//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./IBillboardRegistry.sol";

contract BillboardRegistry is IBillboardRegistry, ERC721 {
    using Counters for Counters.Counter;

    // access control
    address public operator;

    Counters.Counter private _tokenIds;

    uint256 public taxRate;

    // tokenId => Board
    mapping(uint256 => Board) public boards;

    // tokenId => auctionId => Auction
    mapping(uint256 => mapping(uint256 => Auction)) public boardAuctions;

    // tokenId => lastAuctionId
    mapping(uint256 => uint256) public lastBoardAuctionId;

    // board creator => TaxTreasury
    mapping(address => TaxTreasury) public taxTreasury;

    constructor(
        address operator_,
        string memory name_,
        string memory symbol_,
        uint256 taxRate_
    ) ERC721(name_, symbol_) {
        operator = operator_;
        taxRate = taxRate_;
    }

    //////////////////////////////
    /// Modifier
    //////////////////////////////

    modifier isFromOperator() {
        if (msg.sender != operator) {
            revert Unauthorized("operator");
        }
        _;
    }

    /// @inheritdoc IBillboardRegistry
    function mint(address to_) external isFromOperator returns (uint256 tokenId) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(to_, newTokenId);

        Board memory newBoard = Board({creator: to_});
        boards[newTokenId] = newBoard;

        // TODO
        // emit Mint(newBoardId, to_);

        return newTokenId;
    }

    /// @inheritdoc IBillboardRegistry
    function setBoard(
        uint256 tokenId_,
        string memory name_,
        string memory description_,
        string memory location_
    ) external isFromOperator {
        boards[tokenId_].name = name_;
        boards[tokenId_].description = description_;
        boards[tokenId_].location = location_;
    }

    /// @inheritdoc IBillboardRegistry
    function setBoard(uint256 tokenId_, string memory contentUri_, string memory redirectUri_) external isFromOperator {
        boards[tokenId_].contentUri_ = contentUri_;
        boards[tokenId_].redirectUri_ = redirectUri_;
    }

    /// @inheritdoc IBillboardRegistry
    function newAuction(uint256 tokenId_, uint256 startAt_, uint256 endAt_) external returns (uint256 auctionId) {
        auctionId = lastBoardAuctionId[tokenId_]++;

        Auction({startAt: startAt_, endAt: endAt_, tokenId: tokenId_});
    }

    /// @inheritdoc IBillboardRegistry
    function setAuction(uint256 tokenId_, uint256 auctionId_, uint256 startAt_, uint256 endAt_) external {
        boardAuctions[tokenId_][auctionId_].startAt = startAt_;
        boardAuctions[tokenId_][auctionId_].endAt = endAt_;
    }

    /// @inheritdoc IBillboardRegistry
    function newBid(uint256 tokenId_, uint256 auctionId_, address bidder_, uint256 price_, uint256 tax_) external {
        Bid bid = Bid({
            bidder: bidder_,
            price: price_,
            tax: tax_,
            auctionId: auctionId_,
            isWithdrawn: false,
            isWon: false
        });

        boardAuctions[tokenId_][auctionId_].bids.push(bid);
    }

    /// @inheritdoc IBillboardRegistry
    function setBid(uint256 tokenId_, uint256 auctionId_, address bidder_, bool isWon_, bool isWithdrawn_) external {
        boardAuctions[tokenId_][auctionId_].bids[bidder_].isWon = isWon_;
        boardAuctions[tokenId_][auctionId_].bids[bidder_].isWithdrawn = isWithdrawn_;
    }

    /// @inheritdoc IBillboardRegistry
    function transferBidAmount(uint256 tokenId_, uint256 auctionId_, address bidder_, address to_) external {
        uint256 amount = boardAuctions[tokenId_][auctionId_].bids[bidder_].price;

        (bool success, ) = to_.call{value: amount}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    /// @inheritdoc IBillboardRegistry
    function setTaxRate(uint256 taxRate_) external {
        taxRate = taxRate_;
    }

    /// @inheritdoc IBillboardRegistry
    function setTaxTreasury(address owner_, uint256 accumulated_, uint256 withdrawn_) external {
        taxTreasury[owner_].accumulated = accumulated_;
        taxTreasury[owner_].withdrawn = withdrawn_;
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
    function transferFrom(address from_, address to_, uint256 tokenId_) public override(ERC721, IERC721) {
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
    ) public override(ERC721, IERC721) {
        if (!_isApprovedOrOwner(msg.sender, tokenId_)) {
            revert Unauthorized("not owner nor approved");
        }
        _safeTransfer(from_, to_, tokenId_, data_);
        boards[tokenId_].tenant = to_;
    }
}
