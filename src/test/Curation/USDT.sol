//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDT is ERC20 {
    constructor(address account_, uint256 amount_) ERC20("USDT", "USDT") {
        _mint(account_, amount_ * (10**uint256(decimals())));
    }
}
