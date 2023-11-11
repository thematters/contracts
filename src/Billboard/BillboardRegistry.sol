//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./IBillboardRegistry.sol";

contract BillboardRegistry is IBillboardRegistry, ERC721 {
    using Counters for Counters.Counter;

    // access control
    bool public isOpened = false;
    address public admin;
    address public operator;
    mapping(address => bool) public whitelist;

    Counters.Counter private _tokenIds;

    // tokenId => Board
    mapping(uint256 => Board) public boards;

    // tokenId => auctionId => Auction
    mapping(uint256 => mapping(uint256 => Auction)) public boardAuctions;

    // tokenId => lastAuctionId
    mapping(uint256 => uint256) public lastBoardAuctionId;

    // board creator => TaxTreasury
    mapping(address => TaxTreasury) public taxTreasury;

    constructor(
        address admin_,
        address operator_,
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {
        admin = admin_;
        operator = operator_;
        whitelist[admin_] = true;
    }

    //////////////////////////////
    /// Modifier
    //////////////////////////////

    modifier isValidAddress(address value_) {
        if (value_ == address(0)) {
            revert InvalidAddress();
        }
        _;
    }

    modifier isBoardCreator(uint256 tokenId_, address value_) {
        if (value_ != boards[tokenId_].creator) {
            revert Unauthorized("board creator");
        }
        _;
    }

    modifier isBoardTenant(uint256 tokenId_, address value_) {
        if (value_ != _ownerOf(tokenId_)) {
            revert Unauthorized("board tenant");
        }
        _;
    }

    modifier isAdmin(address value_) {
        if (value_ != admin) {
            revert Unauthorized("admin");
        }
        _;
    }

    modifier isFromOperator() {
        if (msg.sender != operator) {
            revert Unauthorized("operator");
        }
        _;
    }

    /// @inheritdoc IBillboardRegistry
    function setIsOpened(bool value_, address sender_) external isAdmin(sender_) isFromOperator {
        isOpened = value_;
    }

    /// @inheritdoc IBillboardRegistry
    function addToWhitelist(address value_, address sender_)
        external
        isValidAddress(value_)
        isAdmin(sender_)
        isFromOperator
    {
        whitelist[value_] = true;
    }

    /// @inheritdoc IBillboardRegistry
    function removeFromWhitelist(address value_, address sender_)
        external
        isValidAddress(value_)
        isAdmin(sender_)
        isFromOperator
    {
        delete whitelist[value_];
    }

    /// @inheritdoc IBillboardRegistry
    function mint(address to_, address sender_) external isValidAddress(to_) isFromOperator returns (uint256 tokenId) {
        if (isOpened == false && whitelist[sender_] != true) {
            revert Unauthorized("creator");
        }

        _tokenIds.increment();
        uint256 newBoardId = _tokenIds.current();

        _safeMint(to_, newBoardId);

        Board memory newBoard = Board({
            creator: to_,
            tenant: to_,
            lastHighestBidPrice: 0,
            name: "",
            description: "",
            contentURI: "",
            redirectURI: "",
            location: ""
        });
        boards[newBoardId] = newBoard;

        emit Mint(newBoardId, to_);

        return newBoardId;
    }

    /// @inheritdoc IBillboardRegistry
    function getBoard(uint256 tokenId_) external view returns (Board memory board) {
        return boards[tokenId_];
    }

    /// @inheritdoc IBillboardRegistry
    function setBoardName(
        uint256 tokenId_,
        string memory name_,
        address sender_
    ) external isBoardCreator(tokenId_, sender_) {
        boards[tokenId_].name = name_;
    }

    /// @inheritdoc IBillboardRegistry
    function setBoardDescription(
        uint256 tokenId_,
        string memory description_,
        address sender_
    ) external isBoardCreator(tokenId_, sender_) {
        boards[tokenId_].description = description_;
    }

    /// @inheritdoc IBillboardRegistry
    function setBoardLocation(
        uint256 tokenId_,
        string memory location_,
        address sender_
    ) external isBoardCreator(tokenId_, sender_) {
        boards[tokenId_].location = location_;
    }

    /// @inheritdoc IBillboardRegistry
    function setBoardContentURI(
        uint256 tokenId_,
        string memory uri_,
        address sender_
    ) external isBoardTenant(tokenId_, sender_) {
        boards[tokenId_].contentURI = uri_;
    }

    /// @inheritdoc IBillboardRegistry
    function setBoardRedirectURI(
        uint256 tokenId_,
        string memory redirectURI_,
        address sender_
    ) external isBoardTenant(tokenId_, sender_) {
        boards[tokenId_].redirectURI = redirectURI_;
    }

    /// @inheritdoc IBillboardRegistry
    function setBoardLastHighestBidPrice(uint256 tokenId_, uint256 price_) external isFromOperator {
        boards[tokenId_].lastHighestBidPrice = price_;
    }

    //////////////////////////////
    /// ERC721 Overrides
    //////////////////////////////

    /**
     * @notice See {IERC721-tokenURI}.
     */
    function tokenURI(uint256 tokenId_) public view override(ERC721) returns (string memory uri) {
        return boards[tokenId_].contentURI;
    }

    /**
     * @notice See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner_, address operator_) public view override(ERC721, IERC721) returns (bool) {
        if (operator_ == operator) {
            return true;
        }

        return super.isApprovedForAll(owner_, operator_);
    }

    /**
     * @notice See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public override(ERC721, IERC721) {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    /**
     * @notice See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public override(ERC721, IERC721) isValidAddress(from_) isValidAddress(to_) {
        if (!_isApprovedOrOwner(msg.sender, tokenId_)) {
            revert Unauthorized("not owner nor approved");
        }
        _safeTransfer(from_, to_, tokenId_, data_);
        boards[tokenId_].tenant = to_;
    }
}
