//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./IVault.sol";

contract CurationVault is ICurationVault, Ownable {
    using ECDSA for bytes32;

    address public signer;

    // balances[creatorId][token]
    mapping(string => mapping(address => uint256)) public erc20Balances;

    // balances[creatorId]
    mapping(string => uint256) public nativeBalances;

    // withdrawals[creatorId][expiredAt]
    mapping(string => mapping(uint256 => bool)) public withdrawals;

    constructor(address signer_, address owner_) {
        if (signer_ == address(0) || owner_ == address(0)) {
            revert ZeroAddress();
        }

        signer = signer_;

        // immediately transfer ownership to a multisig
        if (owner_ != address(0)) {
            transferOwnership(owner_);
        }
    }

    /**
     * @notice See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId_) external view virtual returns (bool) {
        return interfaceId_ == type(ICurationVault).interfaceId;
    }

    /// @inheritdoc ICurationVault
    function curate(string calldata uid_, IERC20 token_, uint256 amount_, string calldata uri_) public {
        if (bytes(uid_).length == 0) revert ZeroAddress();
        if (amount_ <= 0) revert ZeroAmount();
        if (bytes(uri_).length == 0) revert InvalidURI();

        SafeERC20.safeTransferFrom(token_, msg.sender, address(this), amount_);

        erc20Balances[uid_][address(token_)] += amount_;

        emit Curation(msg.sender, uid_, token_, uri_, amount_);
    }

    /// @inheritdoc ICurationVault
    function curate(string calldata uid_, string calldata uri_) public payable {
        if (bytes(uid_).length == 0) revert ZeroAddress();
        if (msg.value <= 0) revert ZeroAmount();
        if (bytes(uri_).length == 0) revert InvalidURI();

        nativeBalances[uid_] += msg.value;

        emit Curation(msg.sender, uid_, uri_, msg.value);
    }

    /// @inheritdoc ICurationVault
    function withdraw(
        address to_,
        string calldata uid_,
        IERC20 token_,
        uint256 expiredAt_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) public {
        if (to_ == address(0)) revert ZeroAddress();

        // Check if the claim is expired
        if (expiredAt_ < block.timestamp) {
            revert Expired();
        }

        // Check if already withdrawn
        if (withdrawals[uid_][expiredAt_]) {
            revert AlreadyWithdrawn();
        }
        withdrawals[uid_][expiredAt_] = true;

        // Verify the signature
        bytes32 hash = keccak256(abi.encodePacked(to_, uid_, token_, expiredAt_, address(this)))
            .toEthSignedMessageHash();
        if (!_verify(hash, v_, r_, s_)) {
            revert InvalidSignature();
        }

        // Check if balance is enough
        uint256 amount_ = erc20Balances[uid_][address(token_)];
        if (amount_ <= 0) revert ZeroAmount();
        erc20Balances[uid_][address(token_)] = 0;

        // Transfer
        SafeERC20.safeTransfer(token_, to_, amount_);

        emit Withdraw(to_, uid_, token_, amount_);
    }

    /// @inheritdoc ICurationVault
    function withdraw(address to_, string calldata uid_, uint256 expiredAt_, uint8 v_, bytes32 r_, bytes32 s_) public {
        if (to_ == address(0)) revert ZeroAddress();

        // Check if the claim is expired
        if (expiredAt_ < block.timestamp) {
            revert Expired();
        }

        // Check if already withdrawn
        if (withdrawals[uid_][expiredAt_]) {
            revert AlreadyWithdrawn();
        }
        withdrawals[uid_][expiredAt_] = true;

        // Verify the signature
        bytes32 hash = keccak256(abi.encodePacked(to_, uid_, expiredAt_, address(this))).toEthSignedMessageHash();
        if (!_verify(hash, v_, r_, s_)) {
            revert InvalidSignature();
        }

        // Check if balance is enough
        uint256 amount_ = nativeBalances[uid_];
        if (amount_ <= 0) revert ZeroAmount();
        nativeBalances[uid_] = 0;

        // Transfer
        (bool success, ) = to_.call{value: amount_}("");
        if (!success) revert TransferFailed();

        emit Withdraw(to_, uid_, amount_);
    }

    /// @inheritdoc ICurationVault
    function setSigner(address signer_) external onlyOwner {
        if (signer_ == address(0)) revert ZeroAddress();

        signer = signer_;
        emit SignerChanged(signer_);
    }

    /**
     * @dev verify if a signature is signed by signer
     */
    function _verify(bytes32 hash_, uint8 v_, bytes32 r_, bytes32 s_) internal view returns (bool isSignedBySigner) {
        address recoveredAddress = hash_.recover(v_, r_, s_);
        isSignedBySigner = recoveredAddress != address(0) && recoveredAddress == signer;
    }
}
