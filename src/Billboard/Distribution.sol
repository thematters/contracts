// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./IDistribution.sol";

// https://github.com/Uniswap/merkle-distributor
contract Distribution is IDistribution, Ownable {
    address public admin;
    address public immutable token;

    // treeId_ => merkleRoot_
    mapping(string => bytes32) public merkleRoots;

    // treeId_ => balance_
    mapping(string => uint256) public balances;

    // treeId_ => totalAmount_
    mapping(string => uint256) public totalAmounts;

    // treeId_ => cid_ => account_
    mapping(string => mapping(string => mapping(address => bool))) public hasClaimed;

    constructor(address token_, address admin_) {
        require(token_ != address(0), "Zero address");
        require(admin_ != address(0), "Zero address");

        admin = admin_;
        token = token_;
    }

    //////////////////////////////
    /// Access control
    //////////////////////////////

    modifier isFromAdmin() {
        require(msg.sender == admin, "Admin");
        _;
    }

    /// @inheritdoc IDistribution
    function setAdmin(address account_) external onlyOwner {
        require(account_ != address(0), "Zero address");

        address _prevAdmin = admin;
        admin = account_;
        emit AdminChanged(_prevAdmin, admin);
    }

    //////////////////////////////
    /// Drop & claim
    //////////////////////////////

    /// @inheritdoc IDistribution
    function drop(string calldata treeId_, bytes32 merkleRoot_, uint256 amount_) external isFromAdmin {
        require(amount_ > 0, "Zero amount");

        // Set the merkle root
        require(merkleRoots[treeId_] == bytes32(0), "Existing tree");
        merkleRoots[treeId_] = merkleRoot_;

        emit Drop(treeId_, amount_);

        // Set the balance & total amount for the tree
        balances[treeId_] = amount_;
        totalAmounts[treeId_] = amount_;

        // Transfer
        SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount_);
    }

    /// @inheritdoc IDistribution
    function claim(
        string calldata treeId_,
        string calldata cid_,
        address account_,
        uint256 share_,
        bytes32[] calldata merkleProof_
    ) external {
        require(!hasClaimed[treeId_][cid_][account_], "Already claimed");

        bytes32 _root = merkleRoots[treeId_];
        require(_root != bytes32(0), "Invalid tree ID");

        // Verify the merkle proof
        bytes32 _leaf = keccak256(bytes.concat(keccak256(abi.encode(cid_, account_, share_))));
        require(MerkleProof.verify(merkleProof_, _root, _leaf), "Invalid proof");

        // Mark it as claimed first for to prevent reentrancy
        hasClaimed[treeId_][cid_][account_] = true;

        uint256 amount_ = calculateAmount(share_, totalAmounts[treeId_]);

        emit Claim(cid_, account_, amount_);

        // Update the balance for the tree
        balances[treeId_] -= amount_;

        // Transfer
        require(IERC20(token).transfer(account_, amount_), "Failed token transfer");
    }

    /// @inheritdoc IDistribution
    function sweep(string calldata treeId_, address target_) external isFromAdmin {
        uint256 _balance = balances[treeId_];

        require(_balance > 0, "Zero balance");

        // Update the balance for the tree
        balances[treeId_] = 0;

        // Transfer
        require(IERC20(token).transfer(target_, _balance), "Failed token transfer");
    }

    function calculateAmount(uint256 share_, uint256 totalAmount_) public pure returns (uint256 amount) {
        amount = (totalAmount_ * share_) / 10000;
    }
}
