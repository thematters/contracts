//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IVault.sol";

using ECDSA for bytes32;

contract Vault is IVault, Ownable {
    address public signer;

    // id => token => amount
    mapping(bytes32 => mapping(address => uint256)) public balances;
    mapping(bytes32 => mapping(address => uint256)) public claimed;

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
    function claim(
        bytes32 id_,
        address token_,
        address target_,
        uint256 expiredAt_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external returns (bool success) {
        // Check if the claim is expired
        if (expiredAt_ < block.timestamp) {
            revert ClaimExpired();
        }

        // Check available balance
        uint256 _balance = balances[id_][token_];
        uint256 _claimed = claimed[id_][token_];
        uint256 _available = _balance - _claimed;
        if (_available <= 0) {
            revert NotEnoughBalance();
        }

        // Verify the signature
        bytes32 hash = keccak256(abi.encodePacked(id_, token_, target_, expiredAt_, address(this)))
            .toEthSignedMessageHash();
        if (!_verify(hash, v_, r_, s_)) {
            revert InvalidSignature();
        }

        // Claim all available tokens
        claimed[id_][token_] = 0;

        // Transfer tokens
        emit Claimed(id_, token_, target_, _available);

        require(IERC20(token_).transfer(target_, _balance), "Failed token transfer");

        return true;
    }

    /// @inheritdoc IVault
    function sweep(address token_, address target_) external onlyOwner {
        uint256 _balance = IERC20(token_).balanceOf(address(this));

        emit Swept(token_, target_, _balance);

        require(IERC20(token_).transfer(target_, _balance), "Failed token transfer");
    }

    /// @inheritdoc IVault
    function setSigner(address signer_) external onlyOwner {
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
