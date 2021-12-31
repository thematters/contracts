//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @dev DAO that pays dividends based on shares.
 */
interface IDividendDAO {
    /**
     * @dev Emitted when a dividend is distributed
     */
    event Dividend(address indexed to, uint256 amount);

    /**
     * @dev Distribute all outstanding dividends.
     *
     * Emits {Dividend} events.
     */
    function payDividends() external;
}
