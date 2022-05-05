//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @notice ERC20 token used in _The Space_.
 * @dev Total supply capped at 100M, minted to deployer.
 */
contract SpaceToken is ERC20 {
    constructor() ERC20("The Space", "SPACE") {
        _mint(msg.sender, 10 * 10**8 * (10**uint256(decimals())));
    }
}
