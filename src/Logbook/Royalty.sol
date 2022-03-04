//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IRoyalty.sol";

abstract contract Royalty is IRoyalty, Ownable {
    mapping(address => uint256) internal _balances;

    /// @inheritdoc IRoyalty
    function withdraw() public {
        uint256 amount = _balances[msg.sender];

        if (amount == 0) revert ZeroAmount();
        if (address(this).balance < amount) revert InsufficientBalance(address(this).balance, amount);

        _balances[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);

        emit Withdraw(msg.sender, amount);
    }

    /// @inheritdoc IRoyalty
    function getBalance(address account_) public view returns (uint256) {
        return _balances[account_];
    }
}
