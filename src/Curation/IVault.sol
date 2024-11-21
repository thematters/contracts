//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title The interface for {CurationVault} contract
 * @notice CurationVault is the contract for off-chain content curation.
 *
 * Curate:
 * - Any address (curator) can send native or ERC-20 tokens to domain-specific ID (content creator) to curate the specific content.
 * - Tokens will be locked in the contract.
 *
 * Withdraw:
 * - Contract owner can withdraw locked tokens to a given address.
 */
interface ICurationVault {
    /**
     * @notice Zero ID or address is invalid.
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
     * @notice Invalid signature.
     */
    error InvalidSignature();

    /**
     * @notice Content curation with ERC-20 token.
     * @param from Address of content curator.
     * @param to Domain-specific ID of content creator.
     * @param uri Content URI.
     * @param token ERC20 token address.
     * @param amount Amount of tokens to curate.
     */
    event Curation(address indexed from, string indexed to, IERC20 indexed token, string uri, uint256 amount);

    /**
     * @notice Content curation with native token.
     * @param from Address of content curator.
     * @param to Domain-specific ID of content creator.
     * @param uri Content URI.
     * @param amount Amount of tokens to curate.
     */
    event Curation(address indexed from, string indexed to, string uri, uint256 amount);

    /**
     * @notice Native token withdrawal.
     * @param to Address to withdraw tokens.
     * @param amount Amount of tokens to withdraw.
     */
    event Withdraw(address indexed to, uint256 amount);

    /**
     * @notice ERC-20 token withdrawal.
     * @param to Address to withdraw tokens.
     * @param token ERC20 token address.
     * @param amount Amount of tokens to withdraw.
     */
    event Withdraw(address indexed to, IERC20 indexed token, uint256 amount);

    /**
     * @notice Curate content by ERC-20 token donation.
     *
     * @dev Emits: {Curation} event.
     * @dev Throws: {ZeroAddress}, {ZeroAmount}, {InvalidURI} error.
     *
     * @param to_ Domain-specific ID of content creator.
     * @param token_ ERC20 token address.
     * @param amount_ Amount of tokens to curate.
     * @param uri_ Content URI.
     */
    function curate(string calldata to_, IERC20 token_, uint256 amount_, string calldata uri_) external;

    /**
     * @notice Curate content by native token donation.
     *
     * @dev Emits: {Curation} event.
     * @dev Throws: {ZeroAddress}, {ZeroAmount}, {InvalidURI} error.
     *
     * @param to_ Domain-specific ID of content creator.
     * @param uri_ Content URI.
     */
    function curate(string calldata to_, string calldata uri_) external payable;

    /**
     * @notice Withdraw locked tokens to a given address.
     *
     * @dev Emits: {Withdraw} event.
     * @dev Throws: {ZeroAddress}, {TransferFailed}, {InvalidSignature} error.
     *
     * @param to_ Address to withdraw tokens.
     * @param hashedMessage_ Hashed message.
     * @param v_ ECDSA signature v.
     * @param r_ ECDSA signature r.
     * @param s_ ECDSA signature s.
     */
    function withdraw(address to_, bytes32 hashedMessage_, uint8 v_, bytes32 r_, bytes32 s_) external;
}
