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

    // tokenId => nextAuctionId (start from 1)
    mapping(uint256 => uint256) public nextBoardAuctionId;

    // auctionId => bidders
    mapping(uint256 => address[]) public auctionBidders;

    // auctioId => bidder => Bid
    mapping(uint256 => mapping(address => Bid)) auctionBids;

    // board creator => TaxTreasury
    mapping(address => TaxTreasury) public taxTreasury;

    constructor(
        address operator_,
        uint256 taxRate_,
        string memory name_,
        string memory symbol_
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
    function setOperator(address operator_) external isFromOperator {
        operator = operator_;
    }

    //////////////////////////////
    /// Board
    //////////////////////////////

    /// @inheritdoc IBillboardRegistry
    function mintBoard(address to_) external isFromOperator returns (uint256 tokenId) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(to_, newTokenId);

        Board memory _newBoard = Board({
            creator: to_,
            auctionId: 0,
            name: "",
            description: "",
            location: "",
            contentURI: "",
            redirectURI: ""
        });
        boards[newTokenId] = _newBoard;

        // TODO
        // emit Mint(newBoardId, to_);

        return newTokenId;
    }

    /// @inheritdoc IBillboardRegistry
    function safeTransferByOperator(address from_, address to_, uint256 tokenId_) external isFromOperator {
        _safeTransfer(from_, to_, tokenId_, "");
    }

    /// @inheritdoc IBillboardRegistry
    function getBoard(uint256 tokenId_) external view returns (Board memory board) {
        board = boards[tokenId_];
    }

    /// @inheritdoc IBillboardRegistry
    function setBoardAuctionId(uint256 tokenId_, uint256 auctionId_) external isFromOperator {
        boards[tokenId_].auctionId = auctionId_;
    }

    /// @inheritdoc IBillboardRegistry
    function setBoardName(uint256 tokenId_, string calldata name_) external isFromOperator {
        boards[tokenId_].name = name_;
    }

    /// @inheritdoc IBillboardRegistry
    function setBoardDescription(uint256 tokenId_, string calldata description_) external isFromOperator {
        boards[tokenId_].description = description_;
    }

    /// @inheritdoc IBillboardRegistry
    function setBoardLocation(uint256 tokenId_, string calldata location_) external isFromOperator {
        boards[tokenId_].location = location_;
    }

    /// @inheritdoc IBillboardRegistry
    function setBoardContentURI(uint256 tokenId_, string calldata contentURI_) external isFromOperator {
        boards[tokenId_].contentURI = contentURI_;
    }

    function setBoardRedirectURI(uint256 tokenId_, string calldata redirectURI_) external isFromOperator {
        boards[tokenId_].redirectURI = redirectURI_;
    }

    //////////////////////////////
    /// Auction
    //////////////////////////////

    /// @inheritdoc IBillboardRegistry
    function getAuction(uint256 tokenId_, uint256 auctionId_) external view returns (Auction memory auction) {
        auction = boardAuctions[tokenId_][auctionId_];
    }

    /// @inheritdoc IBillboardRegistry
    function newAuction(
        uint256 tokenId_,
        uint256 startAt_,
        uint256 endAt_
    ) external isFromOperator returns (uint256 newAuctionId) {
        newAuctionId = nextBoardAuctionId[tokenId_]++;

        Auction({
            tokenId: tokenId_,
            startAt: startAt_,
            endAt: endAt_,
            leaseStartAt: 0,
            leaseEndAt: 0,
            highestBidder: address(0)
        });
    }

    /// @inheritdoc IBillboardRegistry
    function setAuctionLease(
        uint256 tokenId_,
        uint256 auctionId_,
        uint256 leaseStartAt_,
        uint256 leaseEndAt_
    ) external isFromOperator {
        boardAuctions[tokenId_][auctionId_].leaseStartAt = leaseStartAt_;
        boardAuctions[tokenId_][auctionId_].leaseEndAt = leaseEndAt_;
    }

    /// @inheritdoc IBillboardRegistry
    function getBidCount(uint256 auctionId_) external view returns (uint256 count) {
        count = auctionBidders[auctionId_].length;
    }

    /// @inheritdoc IBillboardRegistry
    function getBid(uint256 auctionId_, address bidder_) external view returns (Bid memory bid) {
        bid = auctionBids[auctionId_][bidder_];
    }

    /// @inheritdoc IBillboardRegistry
    function newBid(
        uint256 tokenId_,
        uint256 auctionId_,
        address bidder_,
        uint256 price_,
        uint256 tax_
    ) external isFromOperator {
        Bid memory _bid = Bid({
            bidder: bidder_,
            price: price_,
            tax: tax_,
            auctionId: auctionId_,
            placedAt: block.timestamp,
            isWithdrawn: false,
            isWon: false
        });

        auctionBids[auctionId_][bidder_] = _bid;
        auctionBidders[auctionId_].push(bidder_);
    }

    /// @inheritdoc IBillboardRegistry
    function setBidWon(uint256 tokenId_, uint256 auctionId_, address bidder_, bool isWon_) external isFromOperator {
        auctionBids[auctionId_][bidder_].isWon = isWon_;
    }

    /// @inheritdoc IBillboardRegistry
    function setBidWithdrawn(
        uint256 tokenId_,
        uint256 auctionId_,
        address bidder_,
        bool isWithdrawn_
    ) external isFromOperator {
        auctionBids[auctionId_][bidder_].isWithdrawn = isWithdrawn_;
    }

    /// @inheritdoc IBillboardRegistry
    function transferAmount(address to_, uint256 amount_) external isFromOperator {
        (bool _success, ) = to_.call{value: amount_}("");
        if (!_success) {
            revert TransferFailed();
        }
    }

    //////////////////////////////
    /// Tax & Withdraw
    //////////////////////////////

    /// @inheritdoc IBillboardRegistry
    function setTaxRate(uint256 taxRate_) external isFromOperator {
        taxRate = taxRate_;
    }

    /// @inheritdoc IBillboardRegistry
    function setTaxTreasury(address owner_, uint256 accumulated_, uint256 withdrawn_) external isFromOperator {
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
    }
}
