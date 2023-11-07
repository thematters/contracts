//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBillboardRegistry is IERC721 {
    //////////////////////////////
    /// Error
    //////////////////////////////

    error AdminNotFound();

    error BoardNotFound();

    error InvalidBoardId();

    error InvalidAddress();

    error OperatorNotFound();

    error Unauthorized(string type_);

    //////////////////////////////
    /// Event
    //////////////////////////////

    event Mint(uint256 indexed tokenId_, address to_);

    event Transfer(uint256 indexed tokenId_, address from_, address to_);

    //////////////////////////////
    /// Struct
    //////////////////////////////

    struct Board {
        address creator;
        address tenant;
        uint256 lastHighestBidPrice;
        string name;
        string description;
        string location;
        string contentURI;
        string redirectURI;
    }

    /**
     * @notice Toggle for operation access.
     *
     * @param value_ Value of access state.
     * @param sender_ Address of user who wants to set.
     */
    function setIsOpened(bool value_, address sender_) external;

    /**
     * @notice Mint a new board (NFT).
     *
     * @param to_ Address of the new board receiver.
     * @param sender_ Address of user who wants to mint.
     *
     * @return tokenId Token ID of the new board.
     */
    function mint(address to_, address sender_) external returns (uint256 tokenId);

    /**
     * @notice Get a board data.
     *
     * @param tokenId_ Token ID of a board.
     *
     * @return board Board data.
     */
    function getBoard(uint256 tokenId_) external view returns (Board memory board);

    /**
     * @notice Set the name of a board.
     *
     * @param tokenId_ Token ID of a board.
     * @param name_ Board name.
     * @param sender_ Address of user who wants to set.
     */
    function setBoardName(
        uint256 tokenId_,
        string memory name_,
        address sender_
    ) external;

    /**
     * @notice Set the description of a board.
     *
     * @param tokenId_ Token ID of a board.
     * @param description_ Board description.
     * @param sender_ Address of user who wants to set.
     */
    function setBoardDescription(
        uint256 tokenId_,
        string memory description_,
        address sender_
    ) external;

    /**
     * @notice Set the location of a board.
     *
     * @param tokenId_ Token ID of a board.
     * @param location_ Digital address where a board located.
     * @param sender_ Address of user who wants to set.
     */
    function setBoardLocation(
        uint256 tokenId_,
        string memory location_,
        address sender_
    ) external;

    /**
     * @notice Set the content URI of a board.
     *
     * @param tokenId_ Token ID of a board.
     * @param uri_ Content URI of a board.
     * @param sender_ Address of user who wants to set.
     */
    function setBoardContentURI(
        uint256 tokenId_,
        string memory uri_,
        address sender_
    ) external;

    /**
     * @notice Set the redirect URI of a board when users clicking.
     *
     * @param tokenId_ Token ID of a board.
     * @param redirectURI_ Redirect URI when users clicking.
     * @param sender_ Address of user who wants to set.
     */
    function setBoardRedirectURI(
        uint256 tokenId_,
        string memory redirectURI_,
        address sender_
    ) external;

    /**
     * @notice Update the last highest bid price of a board.
     *
     * @param tokenId_ Token ID of a board.
     * @param price_ Bid price.
     */
    function setBoardLastHighestBidPrice(uint256 tokenId_, uint256 price_) external;
}
