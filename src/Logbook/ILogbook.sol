//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IRoyalty.sol";

/**
 * @title The interface for Logbook core contract
 * @dev The interface is inherited from IERC721 (for logbook as NFT) and IRoyalty (for royalty)
 */
interface ILogbook is IRoyalty, IERC721 {
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
     * @notice Emitted when logbook owner publish a new log
     * @param tokenId Logbook token id
     * @param author Logbook owner address
     * @param contentHash Deterministic unique ID, hash of the content
     * @param content Content string
     */
    event Publish(uint256 indexed tokenId, address indexed author, bytes32 indexed contentHash, string content);

    /**
     * @notice Emitted when a logbook was forked
     * @param tokenId Logbook token id
     * @param newTokenId New logbook token id
     * @param owner New logbook owner address
     * @param contentHash End position of a range of logs in the old logbook
     * @param amount Fork price
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
    function multicall(bytes[] calldata data) external returns (bytes[] memory results);

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
     * @param contentHash_ End position of a range of logs in the old logbook
     */
    function fork(uint256 tokenId_, bytes32 contentHash_) external payable;

    /**
     * @notice Pay to fork a logbook with commission
     * @dev Emits {Fork} and {Pay} events
     * @param tokenId_ Logbook token id
     * @param contentHash_ End position of a range of logs in the old logbook
     * @param commission_ Address (frontend operator) to earn commission
     * @param commissionBPS_ Basis points of the commission
     */
    function forkWithCommission(
        uint256 tokenId_,
        bytes32 contentHash_,
        address commission_,
        uint128 commissionBPS_
    ) external payable;

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
    function donateWithCommission(
        uint256 tokenId_,
        address commission_,
        uint128 commissionBPS_
    ) external payable;

    /**
     * @notice Get a logbook
     * @param tokenId_ Logbook token id
     * @return forkPrice Fork price
     * @return contentHashes All logs' content hashes
     * @return authors All logs' authors
     */
    function getLogbook(uint256 tokenId_)
        external
        view
        returns (
            uint256 forkPrice,
            bytes32[] memory contentHashes,
            address[] memory authors
        );

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
     * @notice Toggle public sale state
     * @dev Access Control: contract deployer
     */
    function togglePublicSale() external returns (uint128 publicSale);
}
