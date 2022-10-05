//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title The interface for `Curation` contract
 * @notice Curation is the initial version for on-chain content curation.
 * It's permissionless, any address (curator) can send native or ERC-20 tokens to content creator's address to curate the specific content.
 * @dev This is a stateless contract, it only emits events and no storage access.
 */
interface ICuration {
    /**
     * @notice Zero address is invalid.
     */
    error ZeroAddress();

    /**
     * @notice Amount should be greater than zero.
     */
    error ZeroAmount();

    /**
     * @notice Failed to transfer.
     */
    error TransferFailed();

    /**
     * @notice Invalid URI.
     */
    error InvalidURI();

    /**
     * @notice Self-curation is invalid.
     */
    error SelfCuration();

    /**
     * @notice Content curation with ERC-20 token.
     * @param from Address of content curator.
     * @param to Address of content creator.
     * @param uri Content URI.
     * @param token ERC20 token address.
     * @param amount Amount of tokens to curate.
     */
    event Curation(address indexed from, address indexed to, string indexed uri, IERC20 token, uint256 amount);

    /**
     * @notice Content curation with native token.
     * @param from Address of content curator.
     * @param to Address of content creator.
     * @param uri Content URI.
     * @param amount Amount of tokens to curate.
     */
    event Curation(address indexed from, address indexed to, string indexed uri, uint256 amount);

    /**
     * @notice Curate content by ERC-20 token donation.
     *
     * @dev Emits: `Curation` event.
     * @dev Throws: `ZeroAddress`, `ZeroAmount`, `InvalidURI` or `SelfCuration` error.
     *
     * @param to_ Address of content creator.
     * @param token_ ERC20 token address.
     * @param amount_ Amount of tokens to curate.
     * @param uri_ Content URI.
     */
    function curate(
        address to_,
        IERC20 token_,
        uint256 amount_,
        string calldata uri_
    ) external;

    /**
     * @notice Curate content by native token donation.
     *
     * @dev Emits: `Curation` event.
     * @dev Throws: `ZeroAddress`, `ZeroAmount`, `InvalidURI` or `SelfCuration` error.
     *
     * @param to_ Address of content creator.
     * @param uri_ Content URI.
     */
    function curate(address to_, string calldata uri_) external payable;
}
