//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./IBillboardRegistry.sol";

contract BillboardRegistry is IBillboardRegistry, ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter public lastTokenId;

    address public operator;

    // token to be used for auction
    IERC20 public immutable token;

    // tokenId => Board
    mapping(uint256 => Board) public boards;

    // tokenId => epoch => bidder
    mapping(uint256 => mapping(uint256 => address)) public higgestBidder;

    // tokenId => epoch => bidders
    mapping(uint256 => mapping(uint256 => address[])) public bidders;

    // tokenId => epoch => bidder => Bid
    mapping(uint256 => mapping(uint256 => mapping(address => Bid))) public bids;

    // board creator => TaxTreasury
    mapping(address => TaxTreasury) public taxTreasury;

    //////////////////////////////
    /// Constructor
    //////////////////////////////
    constructor(address token_, address operator_, string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        require(operator_ != address(0), "Zero address");
        require(token_ != address(0), "Zero address");
        operator = operator_;
        token = IERC20(token_);
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
    function getBoard(uint256 tokenId_) external view returns (Board memory board) {
        board = boards[tokenId_];
    }

    /// @inheritdoc IBillboardRegistry
    function newBoard(
        address to_,
        uint256 taxRate_,
        uint256 epochInterval_
    ) external isFromOperator returns (uint256 tokenId) {
        lastTokenId.increment();
        tokenId = lastTokenId.current();

        _safeMint(to_, tokenId);

        boards[tokenId] = Board({
            creator: to_,
            name: "",
            description: "",
            imageURI: "",
            location: "",
            taxRate: taxRate_,
            epochInterval: epochInterval_,
            createdAt: block.number
        });

        emit BoardCreated(tokenId, to_, taxRate_, epochInterval_);
    }

    /// @inheritdoc IBillboardRegistry
    function setBoard(
        uint256 tokenId_,
        string calldata name_,
        string calldata description_,
        string calldata imageURI_,
        string calldata location_
    ) external isFromOperator {
        boards[tokenId_].name = name_;
        boards[tokenId_].description = description_;
        boards[tokenId_].imageURI = imageURI_;
        boards[tokenId_].location = location_;
        emit BoardUpdated(tokenId_, name_, description_, imageURI_, location_);
    }

    //////////////////////////////
    /// Auction & Bid
    //////////////////////////////

    /// @inheritdoc IBillboardRegistry
    function getBid(uint256 tokenId_, uint256 auctionId_, address bidder_) external view returns (Bid memory bid) {
        bid = bids[tokenId_][auctionId_][bidder_];
    }

    /// @inheritdoc IBillboardRegistry
    function getBidCount(uint256 tokenId_, uint256 epoch_) external view returns (uint256 count) {
        count = bidders[tokenId_][epoch_].length;
    }

    /// @inheritdoc IBillboardRegistry
    function newBid(
        uint256 tokenId_,
        uint256 epoch_,
        address bidder_,
        uint256 price_,
        uint256 tax_,
        string calldata contentURI_,
        string calldata redirectURI_
    ) external isFromOperator {
        Bid memory _bid = Bid({
            price: price_,
            tax: tax_,
            contentURI: contentURI_,
            redirectURI: redirectURI_,
            createdAt: block.number,
            updatedAt: block.number,
            isWithdrawn: false,
            isWon: false
        });

        // add to auction bids
        bids[tokenId_][epoch_][bidder_] = _bid;

        // add to auction bidders if new bid
        bidders[tokenId_][epoch_].push(bidder_);

        _setHiggestBidder(tokenId_, epoch_, price_, bidder_);

        emit BidUpdated(tokenId_, epoch_, bidder_, price_, tax_, contentURI_, redirectURI_);
    }

    /// @inheritdoc IBillboardRegistry
    function setBid(
        uint256 tokenId_,
        uint256 epoch_,
        address bidder_,
        uint256 price_,
        uint256 tax_,
        string calldata contentURI_,
        string calldata redirectURI_,
        bool hasURIs
    ) external isFromOperator {
        Bid memory _bid = bids[tokenId_][epoch_][bidder_];
        require(_bid.createdAt != 0, "Bid not found");

        _bid.price = price_;
        _bid.tax = tax_;
        _bid.updatedAt = block.number;

        if (hasURIs) {
            _bid.contentURI = contentURI_;
            _bid.redirectURI = redirectURI_;
        }

        _setHiggestBidder(tokenId_, epoch_, price_, bidder_);

        emit BidUpdated(tokenId_, epoch_, bidder_, price_, tax_, contentURI_, redirectURI_);
    }

    // Set auction highest bidder if no highest bidder or price is higher.
    //
    // Note: for same price, the first bidder will always be
    // the highest bidder since the block.number is always greater.
    function _setHiggestBidder(uint256 tokenId_, uint256 epoch_, uint256 price_, address bidder_) internal {
        address highestBidder = higgestBidder[tokenId_][epoch_];
        Bid memory highestBid = bids[tokenId_][epoch_][highestBidder];
        if (highestBidder == address(0) || price_ > highestBid.price) {
            higgestBidder[tokenId_][epoch_] = bidder_;
        }
    }

    /// @inheritdoc IBillboardRegistry
    function setBidURIs(
        uint256 tokenId_,
        uint256 epoch_,
        address bidder_,
        string calldata contentURI_,
        string calldata redirectURI_
    ) external isFromOperator {
        Bid memory _bid = bids[tokenId_][epoch_][bidder_];

        _bid.contentURI = contentURI_;
        _bid.redirectURI = redirectURI_;

        emit BidUpdated(tokenId_, epoch_, bidder_, _bid.price, _bid.tax, contentURI_, redirectURI_);
    }

    /// @inheritdoc IBillboardRegistry
    function setBidWon(uint256 tokenId_, uint256 epoch_, address bidder_, bool isWon_) external isFromOperator {
        bids[tokenId_][epoch_][bidder_].isWon = isWon_;
        emit BidWon(tokenId_, epoch_, bidder_);
    }

    /// @inheritdoc IBillboardRegistry
    function setBidWithdrawn(
        uint256 tokenId_,
        uint256 epoch_,
        address bidder_,
        bool isWithdrawn_
    ) external isFromOperator {
        bids[tokenId_][epoch_][bidder_].isWithdrawn = isWithdrawn_;
        emit BidWithdrawn(tokenId_, epoch_, msg.sender);
    }

    //////////////////////////////
    /// Tax & Withdraw
    //////////////////////////////

    /// @inheritdoc IBillboardRegistry
    function setTaxTreasury(address owner_, uint256 accumulated_, uint256 withdrawn_) external isFromOperator {
        taxTreasury[owner_].accumulated = accumulated_;
        taxTreasury[owner_].withdrawn = withdrawn_;
    }

    //////////////////////////////
    /// Transfer
    //////////////////////////////

    /// @inheritdoc IBillboardRegistry
    function safeTransferByOperator(address from_, address to_, uint256 tokenId_) external isFromOperator {
        _safeTransfer(from_, to_, tokenId_, "");
    }

    /// @inheritdoc IBillboardRegistry
    function transferTokenByOperator(address to_, uint256 amount_) external isFromOperator {
        require(to_ != address(0), "Zero address");
        require(token.transfer(to_, amount_), "Failed token transfer");
    }

    //////////////////////////////
    /// ERC721 Overrides
    //////////////////////////////

    /**
     * @notice See {IERC721-tokenURI}.
     */
    function tokenURI(uint256 tokenId_) public view override(ERC721) returns (string memory uri) {
        // TODO
        // return boards[tokenId_].contentURI;
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
    function emitAuctionCleared(uint256 tokenId_, uint256 epoch_, address highestBidder_) external {
        emit AuctionCleared(tokenId_, epoch_, highestBidder_);
    }

    /// @inheritdoc IBillboardRegistry
    function emitTaxWithdrawn(address owner_, uint256 amount_) external {
        emit TaxWithdrawn(owner_, amount_);
    }
}
