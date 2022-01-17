//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IRoyalty.sol";

abstract contract Royalty is IRoyalty, ReentrancyGuard, Ownable {
    mapping(address => uint256) internal _balances;

    /// @inheritdoc IRoyalty
    function withdraw() public nonReentrant {
        uint256 amount = _balances[msg.sender];
        _balances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);
        emit Withdraw(msg.sender, amount);
    }

    /// @inheritdoc IRoyalty
    function withdrawContractFees() public nonReentrant onlyOwner {
        uint256 amount = _balances[address(this)];
        _balances[address(this)] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);
        emit Withdraw(msg.sender, amount);
    }

    /// @inheritdoc IRoyalty
    function getBalance(address account_) public view returns (uint256) {
        return _balances[account_];
    }
}
