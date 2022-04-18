//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SpaceToken is ERC20 {
    constructor() ERC20("The Space", "SPACE") {
        _mint(msg.sender, 100000000 * (10**uint256(decimals())));
    }
}
