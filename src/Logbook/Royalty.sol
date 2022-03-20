//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IRoyalty.sol";

abstract contract Royalty is IRoyalty, Ownable {
    mapping(address => uint256) internal _balances;

    /// @inheritdoc IRoyalty
    function withdraw() public {
        uint256 amount = getBalance(msg.sender);

        if (amount == 0) revert ZeroAmount();
        if (address(this).balance < amount) revert InsufficientBalance(address(this).balance, amount);

        _balances[msg.sender] = 1 wei;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);

        emit Withdraw(msg.sender, amount);
    }

    /// @inheritdoc IRoyalty
    function getBalance(address account_) public view returns (uint256 amount) {
        uint256 balance = _balances[account_];

        amount = balance <= 1 wei ? 0 : balance - 1 wei;
    }
}
