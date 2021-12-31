//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IPaymentSplitter.sol";

/**
 * @title The interface for Logbook core contract
 * @dev The interface is inherited from IERC721 (for logbook as NFT) and IPaymentSplitter (for royalty)
 */
interface ILogbook is IPaymentSplitter, IERC721 {
    /**
     * @notice Emitted when logbook title was set
     * @param tokenId logbook token id
     * @param title logbook title
     */
    event SetTitle(uint256 indexed tokenId, string title);

    /**
     * @notice Emitted when logbook description was set
     * @param tokenId logbook token id
     * @param description logbook description
     */
    event SetDescription(uint256 indexed tokenId, string description);

    /**
     * @notice Emitted when logbook fork price was set
     * @param tokenId logbook token id
     * @param amount logbook fork price
     */
    event SetForkPrice(uint256 indexed tokenId, uint256 amount);

    /**
     * @notice Emitted when logbook owner publish a new log
     * @param tokenId logbook token id
     * @param author logbook owner address
     * @param contentHash deterministic unique ID, hash of the content
     * @param content content string
     */
    event Publish(
        uint256 indexed tokenId,
        address indexed author,
        bytes32 indexed contentHash,
        string content
    );

    /**
     * @notice Emitted when a logbook was forked
     * @param tokenId logbook token id
     * @param newTokenId new logbook token id
     * @param owner new logbook owner address
     * @param contentHash end position of a range of logs in the old logbook
     * @param amount fork price
     */
    event Fork(
        uint256 indexed tokenId,
        uint256 indexed newTokenId,
        address indexed owner,
        bytes32 contentHash,
        uint256 amount
    );

    /**
     * @notice Emitted when a logbook received a donation
     * @param tokenId logbook token id
     * @param donor donor address
     * @param amount fork price
     */
    event Donate(
        uint256 indexed tokenId,
        address indexed donor,
        uint256 amount
    );

    /**
     * @notice Set logbook title
     * @dev Emits a {SetTitle} event
     * @param tokenId_ logbook token id
     * @param title_ logbook title
     */
    function setTitle(uint256 tokenId_, string calldata title_) external;

    /**
     * @notice Set logbook description
     * @dev Emits a {SetDescription} event
     * @param tokenId_ logbook token id
     * @param description_ logbook description
     */
    function setDescription(uint256 tokenId_, string calldata description_)
        external;

    /**
     * @notice Set logbook fork price
     * @dev Emits a {SetForkPrice} event
     * @param tokenId_ logbook token id
     * @param amount_ fork price
     */
    function setForkPrice(uint256 tokenId_, uint256 amount_) external;

    /**
     * @notice Batch calling methods of this contract
     * @param data array of calldata
     */
    function multicall(bytes[] calldata data)
        external
        returns (bytes[] memory results);

    /**
     * @notice Publish a new log in a logbook
     * @dev Emits a {Publish} event
     * @param tokenId_ logbook token id
     * @param content_ log content
     */
    function publish(uint256 tokenId_, string calldata content_) external;

    /**
     * @notice Pay to fork a logbook
     * @dev Payment will be splited into three parts as royalty fees:
     *     1. 80% to logbook owner
     *     2. 17.5% to logs' authors
     *     3. 2.5% to this contract
     * @dev Emits {Fork} and {Pay} events
     * @param tokenId_ logbook token id
     * @param contentHash_ end position of a range of logs in the old logbook
     */
    function fork(uint256 tokenId_, uint256 contentHash_) external payable;

    /**
     * @notice Donate to a logbook
     * @dev Payment will be splited into three parts as royalty fees:
     *     1. 80% to logbook owner
     *     2. 17.5% to logs' authors
     *     3. 2.5% to this contract
     * @dev Emits {Donate} and {Pay} events
     * @param tokenId_ logbook token id
     */
    function donate(uint256 tokenId_) external payable;

    /**
     * @notice Get a logbook
     * @param tokenId_ logbook token id
     * @return forkPrice fork price
     * @return contentHashes all logs' content hashes
     * @return authors all logs' authors
     */
    function getLogbookLogs(uint256 tokenId_)
        external
        view
        returns (
            uint256 forkPrice,
            bytes32[] memory contentHashes,
            address[] memory authors
        );
}
