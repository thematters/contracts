// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./IDistribution.sol";

// https://github.com/Uniswap/merkle-distributor
contract Distribution is IDistribution, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public lastTreeId;

    // treeId_ => merkleRoot_
    mapping(uint256 => bytes32) public merkleRoots;

    // treeId_ => balance_
    mapping(uint256 => uint256) public balances;

    // treeId_ => cid_ => account_
    mapping(uint256 => mapping(bytes32 => mapping(address => bool))) public hasClaimed;

    /// @inheritdoc IDistribution
    function drop(bytes32 merkleRoot_) external payable onlyOwner returns (uint256 treeId_) {
        require(msg.value > 0, "no value");

        lastTreeId.increment();
        treeId_ = lastTreeId.current();

        // Set the merkle root
        merkleRoots[treeId_] = merkleRoot_;

        // Set the balance
        balances[treeId_] = msg.value;

        emit Drop(treeId_, msg.value);
    }

    /// @inheritdoc IDistribution
    function claim(
        uint256 treeId_,
        bytes32 cid_,
        address account_,
        uint256 amount_,
        bytes32[] calldata merkleProof_
    ) external {
        require(!hasClaimed[treeId_][cid_][account_], "already claimed.");

        // Verify the merkle proof
        bytes32 _leaf = keccak256(abi.encodePacked(cid_, account_, amount_));
        require(MerkleProof.verify(merkleProof_, merkleRoots[treeId_], _leaf), "invalid proof.");

        // Mark it as claimed
        hasClaimed[treeId_][cid_][account_] = true;

        // Transfer
        (bool _success, ) = account_.call{value: amount_}("");
        require(_success, "transfer failed");

        // Update the balance
        balances[treeId_] -= amount_;

        emit Claim(cid_, account_, amount_);
    }

    /// @inheritdoc IDistribution
    function sweep(uint256 treeId_, address target_) external onlyOwner {
        uint256 _balance = balances[treeId_];

        (bool _success, ) = target_.call{value: _balance}("");
        require(_success, "transfer failed");
    }
}
