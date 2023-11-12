//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IRoyalty.sol";

/**
 * @title The interface for Logbook core contract
 * @dev The interface is inherited from IERC721 (for logbook as NFT) and IRoyalty (for royalty)
 */
interface ILogbook is IRoyalty, IERC721 {
    error Unauthorized();
    error InvalidBPS(uint256 min, uint256 max);
    error InvalidTokenId(uint256 min, uint256 max);
    error InsufficientAmount(uint256 available, uint256 required);
    error InsufficientLogs(uint32 maxEndAt);
    error TokenNotExists();
    error PublicSaleNotStarted();

    struct Log {
        address author;
        // logbook that this log first publish to
        uint256 tokenId;
    }

    struct Book {
        // end position of a range of logs
        uint32 endAt;
        // total number of logs
        uint32 logCount;
        // number of transfers
        uint32 transferCount;
        // creation time of the book
        uint160 createdAt;
        // parent book
        uint256 parent;
        // fork price
        uint256 forkPrice;
        // all logs hashes in the book
        bytes32[] contentHashes;
    }

    struct SplitRoyaltyFees {
        uint256 commission;
        uint256 logbookOwner;
        uint256 perLogAuthor;
    }

    /**
     * @notice Emitted when logbook title was set
     * @param tokenId Logbook token id
     * @param title Logbook title
     */
    event SetTitle(uint256 indexed tokenId, string title);

    /**
     * @notice Emitted when logbook description was set
     * @param tokenId Logbook token id
     * @param description Logbook description
     */
    event SetDescription(uint256 indexed tokenId, string description);

    /**
     * @notice Emitted when logbook fork price was set
     * @param tokenId Logbook token id
     * @param amount Logbook fork price
     */
    event SetForkPrice(uint256 indexed tokenId, uint256 amount);

    /**
     * @notice Emitted when a new log was created
     * @param author Author address
     * @param contentHash Deterministic unique ID, hash of the content
     * @param content Content string
     */
    event Content(address indexed author, bytes32 indexed contentHash, string content);

    /**
     * @notice Emitted when logbook owner publish a new log
     * @param tokenId Logbook token id
     * @param contentHash Deterministic unique ID, hash of the content
     */
    event Publish(uint256 indexed tokenId, bytes32 indexed contentHash);

    /**
     * @notice Emitted when a logbook was forked
     * @param tokenId Logbook token id
     * @param newTokenId New logbook token id
     * @param owner New logbook owner address
     * @param end End position of contentHashes of parent logbook (one-based)
     * @param amount Fork price
     */
    event Fork(uint256 indexed tokenId, uint256 indexed newTokenId, address indexed owner, uint32 end, uint256 amount);

    /**
     * @notice Emitted when a logbook received a donation
     * @param tokenId Logbook token id
     * @param donor Donor address
     * @param amount Fork price
     */
    event Donate(uint256 indexed tokenId, address indexed donor, uint256 amount);

    /**
     * @notice Set logbook title
     * @dev Access Control: logbook owner
     * @dev Emits a {SetTitle} event
     * @param tokenId_ logbook token id
     * @param title_ logbook title
     */
    function setTitle(uint256 tokenId_, string calldata title_) external;

    /**
     * @notice Set logbook description
     * @dev Access Control: logbook owner
     * @dev Emits a {SetDescription} event
     * @param tokenId_ Logbook token id
     * @param description_ Logbook description
     */
    function setDescription(uint256 tokenId_, string calldata description_) external;

    /**
     * @notice Set logbook fork price
     * @dev Access Control: logbook owner
     * @dev Emits a {SetForkPrice} event
     * @param tokenId_ Logbook token id
     * @param amount_ Fork price
     */
    function setForkPrice(uint256 tokenId_, uint256 amount_) external;

    /**
     * @notice Batch calling methods of this contract
     * @param data Array of calldata
     */
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);

    /**
     * @notice Publish a new log in a logbook
     * @dev Access Control: logbook owner
     * @dev Emits a {Publish} event
     * @param tokenId_ Logbook token id
     * @param content_ Log content
     */
    function publish(uint256 tokenId_, string calldata content_) external;

    /**
     * @notice Pay to fork a logbook
     * @dev Emits {Fork} and {Pay} events
     * @param tokenId_ Logbook token id
     * @param endAt_ End position of contentHashes of parent logbook  (one-based)
     * @return tokenId New logobok token id
     */
    function fork(uint256 tokenId_, uint32 endAt_) external payable returns (uint256 tokenId);

    /**
     * @notice Pay to fork a logbook with commission
     * @dev Emits {Fork} and {Pay} events
     * @param tokenId_ Logbook token id
     * @param endAt_ End position of contentHashes of parent logbook (one-based)
     * @param commission_ Address (frontend operator) to earn commission
     * @param commissionBPS_ Basis points of the commission
     * @return tokenId New logobok token id
     */
    function forkWithCommission(
        uint256 tokenId_,
        uint32 endAt_,
        address commission_,
        uint256 commissionBPS_
    ) external payable returns (uint256 tokenId);

    /**
     * @notice Donate to a logbook
     * @dev Emits {Donate} and {Pay} events
     * @param tokenId_ Logbook token id
     */
    function donate(uint256 tokenId_) external payable;

    /**
     * @notice Donate to a logbook with commission
     * @dev Emits {Donate} and {Pay} events
     * @param tokenId_ Logbook token id
     * @param commission_ Address (frontend operator) to earn commission
     * @param commissionBPS_ Basis points of the commission
     */
    function donateWithCommission(uint256 tokenId_, address commission_, uint256 commissionBPS_) external payable;

    /**
     * @notice Get a logbook
     * @param tokenId_ Logbook token id
     * @return book Logbook data
     */
    function getLogbook(uint256 tokenId_) external view returns (Book memory book);

    /**
     * @notice Get a logbook's logs
     * @param tokenId_ Logbook token id
     * @return contentHashes All logs' content hashes
     * @return authors All logs' authors
     */
    function getLogs(uint256 tokenId_) external view returns (bytes32[] memory contentHashes, address[] memory authors);

    /**
     * @notice Claim a logbook with a Traveloggers token
     * @dev Access Control: contract deployer
     * @param to_ Traveloggers token owner
     * @param logrsId_ Traveloggers token id (1-1500)
     */
    function claim(address to_, uint256 logrsId_) external;

    /**
     * @notice Mint a logbook
     */
    function publicSaleMint() external payable returns (uint256 tokenId);

    /**
     * @notice Set public sale
     * @dev Access Control: contract deployer
     */
    function setPublicSalePrice(uint256 price_) external;

    /**
     * @notice Turn on public sale
     * @dev Access Control: contract deployer
     */
    function turnOnPublicSale() external;

    /**
     * @notice Turn off public sale
     * @dev Access Control: contract deployer
     */
    function turnOffPublicSale() external;
}
