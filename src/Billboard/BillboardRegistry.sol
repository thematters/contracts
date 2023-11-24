//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./IBillboardRegistry.sol";

contract BillboardRegistry is IBillboardRegistry, ERC721 {
    using Counters for Counters.Counter;

    // access control
    address public operator;

    Counters.Counter public lastTokenId;

    uint256 public taxRate;
    uint64 public constant leaseTerm = 14 days;

    // tokenId => Board
    mapping(uint256 => Board) public boards;

    // tokenId => auctionId => Auction
    mapping(uint256 => mapping(uint256 => Auction)) public boardAuctions;

    // tokenId => nextAuctionId (start from 1 if exists)
    mapping(uint256 => uint256) public nextBoardAuctionId;

    // tokenId => auctionId => bidders
    mapping(uint256 => mapping(uint256 => address[])) public auctionBidders;

    // tokenId => auctionId => bidder => Bid
    mapping(uint256 => mapping(uint256 => mapping(address => Bid))) public auctionBids;

    // board creator => TaxTreasury
    mapping(address => TaxTreasury) public taxTreasury;

    constructor(
        address operator_,
        uint256 taxRate_,
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {
        require(operator_ != address(0), "Zero address");
        operator = operator_;
        taxRate = taxRate_;
    }

    //////////////////////////////
    /// Modifier
    //////////////////////////////

    modifier isFromOperator() {
        require(msg.sender == operator, "Operator");
        _;
    }

    // Function to receive Ether.
    receive() external payable {}

    /// @inheritdoc IBillboardRegistry
    function setOperator(address operator_) external isFromOperator {
        require(operator_ != address(0), "Zero address");

        operator = operator_;

        emit OperatorUpdated(operator_);
    }

    //////////////////////////////
    /// Board
    //////////////////////////////

    /// @inheritdoc IBillboardRegistry
    function mintBoard(address to_) external isFromOperator returns (uint256 tokenId) {
        lastTokenId.increment();
        tokenId = lastTokenId.current();

        _safeMint(to_, tokenId);

        boards[tokenId] = Board({
            creator: to_,
            name: "",
            description: "",
            location: "",
            contentURI: "",
            redirectURI: ""
        });
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
    function setBoardName(uint256 tokenId_, string calldata name_) external isFromOperator {
        boards[tokenId_].name = name_;
        emit BoardNameUpdated(tokenId_, name_);
    }

    /// @inheritdoc IBillboardRegistry
    function setBoardDescription(uint256 tokenId_, string calldata description_) external isFromOperator {
        boards[tokenId_].description = description_;
        emit BoardDescriptionUpdated(tokenId_, description_);
    }

    /// @inheritdoc IBillboardRegistry
    function setBoardLocation(uint256 tokenId_, string calldata location_) external isFromOperator {
        boards[tokenId_].location = location_;
        emit BoardLocationUpdated(tokenId_, location_);
    }

    /// @inheritdoc IBillboardRegistry
    function setBoardContentURI(uint256 tokenId_, string calldata contentURI_) external isFromOperator {
        boards[tokenId_].contentURI = contentURI_;
        emit BoardContentURIUpdated(tokenId_, contentURI_);
    }

    function setBoardRedirectURI(uint256 tokenId_, string calldata redirectURI_) external isFromOperator {
        boards[tokenId_].redirectURI = redirectURI_;
        emit BoardRedirectURIUpdated(tokenId_, redirectURI_);
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
        uint64 startAt_,
        uint64 endAt_
    ) external isFromOperator returns (uint256 newAuctionId) {
        nextBoardAuctionId[tokenId_]++;

        newAuctionId = nextBoardAuctionId[tokenId_];

        boardAuctions[tokenId_][newAuctionId] = Auction({
            startAt: startAt_,
            endAt: endAt_,
            leaseStartAt: 0,
            leaseEndAt: 0,
            highestBidder: address(0)
        });

        emit AuctionCreated(tokenId_, newAuctionId, startAt_, endAt_);
    }

    /// @inheritdoc IBillboardRegistry
    function setAuctionLease(
        uint256 tokenId_,
        uint256 auctionId_,
        uint64 leaseStartAt_,
        uint64 leaseEndAt_
    ) external isFromOperator {
        boardAuctions[tokenId_][auctionId_].leaseStartAt = leaseStartAt_;
        boardAuctions[tokenId_][auctionId_].leaseEndAt = leaseEndAt_;
    }

    /// @inheritdoc IBillboardRegistry
    function getBidCount(uint256 tokenId_, uint256 auctionId_) external view returns (uint256 count) {
        count = auctionBidders[tokenId_][auctionId_].length;
    }

    /// @inheritdoc IBillboardRegistry
    function getBid(uint256 tokenId_, uint256 auctionId_, address bidder_) external view returns (Bid memory bid) {
        bid = auctionBids[tokenId_][auctionId_][bidder_];
    }

    /// @inheritdoc IBillboardRegistry
    function newBid(
        uint256 tokenId_,
        uint256 auctionId_,
        address bidder_,
        uint256 price_,
        uint256 tax_
    ) external isFromOperator {
        Bid memory _bid = Bid({price: price_, tax: tax_, placedAt: block.timestamp, isWithdrawn: false, isWon: false});

        // add to auction bids
        auctionBids[tokenId_][auctionId_][bidder_] = _bid;

        // add to auction bidders
        auctionBidders[tokenId_][auctionId_].push(bidder_);

        // set auction highest bidder if no highest bidder or price is higher.
        //
        // Note: for same price, the first bidder will always be
        // the highest bidder since the block.timestamp is always greater.
        address highestBidder = boardAuctions[tokenId_][auctionId_].highestBidder;
        Bid memory highestBid = auctionBids[tokenId_][auctionId_][highestBidder];
        if (highestBidder == address(0) || price_ > highestBid.price) {
            boardAuctions[tokenId_][auctionId_].highestBidder = bidder_;
        }

        emit BidCreated(tokenId_, auctionId_, bidder_, price_, tax_);
    }

    /// @inheritdoc IBillboardRegistry
    function setBidWon(uint256 tokenId_, uint256 auctionId_, address bidder_, bool isWon_) external isFromOperator {
        auctionBids[tokenId_][auctionId_][bidder_].isWon = isWon_;

        emit BidWon(tokenId_, auctionId_, bidder_);
    }

    /// @inheritdoc IBillboardRegistry
    function setBidWithdrawn(
        uint256 tokenId_,
        uint256 auctionId_,
        address bidder_,
        bool isWithdrawn_
    ) external isFromOperator {
        auctionBids[tokenId_][auctionId_][bidder_].isWithdrawn = isWithdrawn_;
    }

    /// @inheritdoc IBillboardRegistry
    function transferAmount(address to_, uint256 amount_) external isFromOperator {
        require(to_ != address(0), "Zero address");
        (bool _success, ) = to_.call{value: amount_}("");
        require(_success, "transfer failed");
    }

    //////////////////////////////
    /// Tax & Withdraw
    //////////////////////////////

    /// @inheritdoc IBillboardRegistry
    function setTaxRate(uint256 taxRate_) external isFromOperator {
        taxRate = taxRate_;

        emit TaxRateUpdated(taxRate_);
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
     * @notice See {IERC721-transferFrom}.
     */
    function transferFrom(address from_, address to_, uint256 tokenId_) public override(ERC721, IERC721) {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    //////////////////////////////
    /// Event emission
    //////////////////////////////

    /// @inheritdoc IBillboardRegistry
    function emitAuctionCleared(
        uint256 tokenId_,
        uint256 auctionId_,
        address highestBidder_,
        uint64 leaseStartAt_,
        uint64 leaseEndAt_
    ) external {
        emit AuctionCleared(tokenId_, auctionId_, highestBidder_, leaseStartAt_, leaseEndAt_);
    }

    /// @inheritdoc IBillboardRegistry
    function emitBidWithdrawn(
        uint256 tokenId_,
        uint256 auctionId_,
        address bidder_,
        uint256 price_,
        uint256 tax_
    ) external {
        emit BidWithdrawn(tokenId_, auctionId_, bidder_, price_, tax_);
    }

    /// @inheritdoc IBillboardRegistry
    function emitTaxWithdrawn(address owner_, uint256 amount_) external {
        emit TaxWithdrawn(owner_, amount_);
    }
}
