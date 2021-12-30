//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IPaymentSplitter.sol";

interface ILogbook is IPaymentSplitter, IERC721 {
    event SetTitle(uint256 indexed tokenId, string title);
    event SetDescription(uint256 indexed tokenId, string description);
    event SetForkPrice(uint256 indexed tokenId, uint256 forkPrice);
    event Publish(
        uint256 indexed tokenId,
        uint256 indexed logContentHash,
        string content
    );
    event Fork(
        uint256 indexed tokenId,
        uint256 indexed newTokenId,
        address indexed owner,
        uint256 endLogContentHash,
        uint256 amount
    );
    event Donate(
        uint256 indexed tokenId,
        address indexed donor,
        uint256 amount
    );

    /**
     * @dev Set logbook title.
     *
     * Emits a {SetTitle} event.
     */
    function setTitle(
        uint256 tokenId_,
        string calldata title_) external;

    /**
     * @dev Set descrption title.
     *
     * Emits a {SetDescription} event.
     */
    function setDescription(
        uint256 tokenId_,
        string calldata description_) external;

    /**
     * @dev Set logbook fork price.
     *
     * Emits a {SetForkPrice} event.
     */
    function setForkPrice(
        uint256 tokenId_,
        uint256 forkPrice_) external;

    /**
     * @dev Batch calling methods of this contract.
     *
     */
    function multicall(bytes[] calldata data) external returns(bytes[] memory results);

    /**
     * @dev Publish a new log to a logbook.
     *
     * Emits a {Publish} event.
     */
    function publish(uint256 tokenId_, string calldata content_) external;

    /**
     * @dev Fork a logbook.
     *
     * Emits {Fork}, {SplitPayment} events.
     */
    function fork(uint256 tokenId_, uint256 endLogContentHash_) external payable;

    /**
     * @dev Donate to a logbook.
     *
     * Emits {Donate}, {SplitPayment} event.
     */
    function donate(uint256 tokenId) external payable;

    /**
     * @dev Get a logbook.
     *
     */
    function getLogbook(uint256 tokenId_) external view returns (
        uint256[] memory logContentHashes,
        uint256 forkPrice
    );
}
