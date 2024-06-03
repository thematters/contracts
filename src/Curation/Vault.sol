//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IVault.sol";

using ECDSA for bytes32;

contract Vault is IVault, Ownable {
    address public signer;

    // vault id => balance / claimed
    mapping(bytes32 => uint256) public balances;
    mapping(bytes32 => uint256) public claimed;

    // vault id => token => balance / claimed
    mapping(bytes32 => mapping(address => uint256)) public erc20Balances;
    mapping(bytes32 => mapping(address => uint256)) public erc20Claimed;

    // hash => executed
    mapping(bytes32 => bool) public executed;

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

    /// @inheritdoc IVault
    function deposit(bytes32 vaultId_) public payable {
        if (msg.value <= 0) {
            revert ZeroAmount();
        }

        balances[vaultId_] += msg.value;

        emit Deposited(vaultId_, msg.value);
    }

    /// @inheritdoc IVault
    function deposit(bytes32 vaultId_, address token_, uint256 amount_) public {
        if (amount_ <= 0) {
            revert ZeroAmount();
        }

        SafeERC20.safeTransferFrom(IERC20(token_), msg.sender, address(this), amount_);

        erc20Balances[vaultId_][token_] += amount_;

        emit Deposited(vaultId_, token_, amount_);
    }

    /// @inheritdoc IVault
    function claim(bytes32 vaultId_, address target_, uint256 expiredAt_, uint8 v_, bytes32 r_, bytes32 s_) public {
        // Check if the claim is expired
        if (expiredAt_ < block.timestamp) {
            revert ClaimExpired();
        }

        uint256 _balance = balances[vaultId_];
        uint256 _claimed = claimed[vaultId_];
        uint256 _available = _balance - _claimed;
        if (_available <= 0) {
            revert ZeroBalance();
        }

        // Verify the signature
        bytes32 _hash = keccak256(abi.encodePacked(vaultId_, target_, expiredAt_, block.chainid, address(this)))
            .toEthSignedMessageHash();
        if (!_verify(_hash, v_, r_, s_)) {
            revert InvalidSignature();
        }
        if (executed[_hash]) {
            revert AlreadyClaimed();
        }

        // Claim ETH
        claimed[vaultId_] = 0;

        // Transfer tokens
        emit Claimed(vaultId_, target_, _available);

        require(payable(target_).send(_balance), "Failed ETH transfer");
    }

    /// @inheritdoc IVault
    function claim(
        bytes32 vaultId_,
        address token_,
        address target_,
        uint256 expiredAt_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) public {
        // Check if the claim is expired
        if (expiredAt_ < block.timestamp) {
            revert ClaimExpired();
        }

        // Check available balance
        uint256 _balance = erc20Balances[vaultId_][token_];
        uint256 _claimed = erc20Claimed[vaultId_][token_];
        uint256 _available = _balance - _claimed;
        if (_available <= 0) {
            revert ZeroBalance();
        }

        // Verify the signature
        bytes32 _hash = keccak256(abi.encodePacked(vaultId_, token_, target_, expiredAt_, block.chainid, address(this)))
            .toEthSignedMessageHash();
        if (!_verify(_hash, v_, r_, s_)) {
            revert InvalidSignature();
        }
        if (executed[_hash]) {
            revert AlreadyClaimed();
        }

        // Claim the given tokens
        erc20Claimed[vaultId_][token_] = 0;

        // Transfer tokens
        emit Claimed(vaultId_, token_, target_, _available);

        require(IERC20(token_).transfer(target_, _balance), "Failed token transfer");
    }

    /// @inheritdoc IVault
    function sweep(address target_) public onlyOwner {
        uint256 _balance = address(this).balance;

        emit Swept(target_, _balance);

        require(payable(target_).send(_balance), "Failed ETH transfer");
    }

    /// @inheritdoc IVault
    function sweep(address token_, address target_) public onlyOwner {
        uint256 _balance = IERC20(token_).balanceOf(address(this));

        emit Swept(token_, target_, _balance);

        require(IERC20(token_).transfer(target_, _balance), "Failed token transfer");
    }

    /// @inheritdoc IVault
    function setSigner(address signer_) public onlyOwner {
        if (signer_ == address(0)) {
            revert ZeroAddress();
        }

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
