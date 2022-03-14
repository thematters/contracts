//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SpaceToken is ERC20, Ownable {
    constructor() ERC20("SpaceToken", "STK") {
        _mint(msg.sender, 100000000);
    }
}
