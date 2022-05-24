//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @notice ERC20 token used in _The Space_.
 * @dev Total supply capped at 100M, minted to deployer.
 */
contract SpaceToken is ERC20 {
    constructor(
        address incentives,
        uint256 incentivesTokens,
        address treasury,
        uint256 treasuryTokens,
        address team,
        uint256 teamTokens,
        address lp,
        uint256 lpTokens
    ) ERC20("The Space", "SPACE") {
        // Early Incentives
        _mint(incentives, incentivesTokens * (10**uint256(decimals())));

        // Community Treasury
        _mint(treasury, treasuryTokens * (10**uint256(decimals())));

        // Team
        _mint(team, teamTokens * (10**uint256(decimals())));

        // Liquidity Pool
        _mint(lp, lpTokens * (10**uint256(decimals())));
    }
}
