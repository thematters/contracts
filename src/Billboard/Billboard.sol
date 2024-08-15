//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./BillboardRegistry.sol";
import "./IBillboard.sol";
import "./IBillboardRegistry.sol";

contract Billboard is IBillboard {
    // access control
    BillboardRegistry public immutable registry;
    address public immutable admin;

    // tokenId => address => whitelisted
    mapping(uint256 => mapping(address => bool)) public whitelist;

    // tokenId => disabled
    mapping(uint256 => bool) public isBoardWhitelistDisabled;

    // tokenId => closed
    mapping(uint256 => bool) public closed;

    constructor(
        address currency_,
        address payable registry_,
        address admin_,
        string memory name_,
        string memory symbol_
    ) {
        require(admin_ != address(0), "Zero address");
        admin = admin_;

        // deploy operator only
        if (registry_ != address(0)) {
            registry = BillboardRegistry(registry_);
        }
        // deploy operator and registry
        else {
            registry = new BillboardRegistry(currency_, address(this), name_, symbol_);
        }
    }

    //////////////////////////////
    /// Modifiers
    //////////////////////////////

    modifier isFromAdmin() {
        require(msg.sender == admin, "Admin");
        _;
    }

    modifier isFromWhitelist(uint256 tokenId_) {
        require(isBoardWhitelistDisabled[tokenId_] || whitelist[tokenId_][msg.sender], "Whitelist");
        _;
    }

    modifier isNotClosed(uint256 tokenId_) {
        require(closed[tokenId_] != true, "Closed");
        _;
    }

    modifier isFromCreator(uint256 tokenId_) {
        IBillboardRegistry.Board memory _board = registry.getBoard(tokenId_);
        require(_board.creator == msg.sender, "Creator");
        _;
    }

    modifier isFromTenant(uint256 tokenId_) {
        require(msg.sender == registry.ownerOf(tokenId_), "Tenant");
        _;
    }

    //////////////////////////////
    /// Upgradability
    //////////////////////////////

    /// @inheritdoc IBillboard
    function setRegistryOperator(address operator_) external isFromAdmin {
        registry.setOperator(operator_);
    }

    //////////////////////////////
    /// Access control
    //////////////////////////////

    /// @inheritdoc IBillboard
    function setWhitelist(uint256 tokenId_, address account_, bool whitelisted) external isFromCreator(tokenId_) {
        whitelist[tokenId_][account_] = whitelisted;
    }

    /// @inheritdoc IBillboard
    function setBoardWhitelistDisabled(uint256 tokenId_, bool disabled) external isFromCreator(tokenId_) {
        isBoardWhitelistDisabled[tokenId_] = disabled;
    }

    /// @inheritdoc IBillboard
    function setClosed(uint256 tokenId_, bool closed_) external isFromCreator(tokenId_) {
        closed[tokenId_] = closed_;
    }

    //////////////////////////////
    /// Board
    //////////////////////////////

    /// @inheritdoc IBillboard
    function mintBoard(uint256 taxRate_, uint256 epochInterval_) external returns (uint256 tokenId) {
        require(epochInterval_ > 0, "Zero epoch interval");
        tokenId = registry.newBoard(msg.sender, taxRate_, epochInterval_, block.number);
        whitelist[tokenId][msg.sender] = true;
    }

    /// @inheritdoc IBillboard
    function mintBoard(
        uint256 taxRate_,
        uint256 epochInterval_,
        uint256 startedAt_
    ) external returns (uint256 tokenId) {
        require(epochInterval_ > 0, "Zero epoch interval");
        tokenId = registry.newBoard(msg.sender, taxRate_, epochInterval_, startedAt_);
        whitelist[tokenId][msg.sender] = true;
    }

    /// @inheritdoc IBillboard
    function getBoard(uint256 tokenId_) external view returns (IBillboardRegistry.Board memory board) {
        return registry.getBoard(tokenId_);
    }

    /// @inheritdoc IBillboard
    function setBoard(
        uint256 tokenId_,
        string calldata name_,
        string calldata description_,
        string calldata imageURI_,
        string calldata location_
    ) external isFromCreator(tokenId_) {
        registry.setBoard(tokenId_, name_, description_, imageURI_, location_);
    }

    //////////////////////////////
    /// Auction & Bid
    //////////////////////////////

    /// @inheritdoc IBillboard
    function placeBid(
        uint256 tokenId_,
        uint256 epoch_,
        uint256 price_
    ) external payable isNotClosed(tokenId_) isFromWhitelist(tokenId_) {
        _placeBid(tokenId_, epoch_, price_, "", "", false);
    }

    /// @inheritdoc IBillboard
    function placeBid(
        uint256 tokenId_,
        uint256 epoch_,
        uint256 price_,
        string calldata contentURI_,
        string calldata redirectURI_
    ) external payable isNotClosed(tokenId_) isFromWhitelist(tokenId_) {
        _placeBid(tokenId_, epoch_, price_, contentURI_, redirectURI_, true);
    }

    function _placeBid(
        uint256 tokenId_,
        uint256 epoch_,
        uint256 price_,
        string memory contentURI_,
        string memory redirectURI_,
        bool hasURIs
    ) private {
        IBillboardRegistry.Board memory _board = registry.getBoard(tokenId_);
        require(_board.creator != address(0), "Board not found");

        uint256 _endedAt = this.getBlockFromEpoch(_board.startedAt, epoch_ + 1, _board.epochInterval);
        require(block.number < _endedAt, "Auction ended");

        IBillboardRegistry.Bid memory _bid = registry.getBid(tokenId_, epoch_, msg.sender);

        uint256 _tax = calculateTax(tokenId_, price_);

        // create new bid if no bid exists
        if (_bid.placedAt == 0) {
            // transfer bid price and tax to the registry
            SafeERC20.safeTransferFrom(registry.currency(), msg.sender, address(registry), price_ + _tax);

            // add new bid
            registry.newBid(tokenId_, epoch_, msg.sender, price_, _tax, contentURI_, redirectURI_);
        }
        // update bid if exists
        else {
            require(price_ > _bid.price, "Price too low");

            // transfer diff amount to the registry
            uint256 _priceDiff = price_ - _bid.price;
            uint256 _taxDiff = _tax - _bid.tax;
            SafeERC20.safeTransferFrom(registry.currency(), msg.sender, address(registry), _priceDiff + _taxDiff);

            if (hasURIs) {
                registry.setBid(tokenId_, epoch_, msg.sender, price_, _tax, contentURI_, redirectURI_, true);
            } else {
                registry.setBid(tokenId_, epoch_, msg.sender, price_, _tax, "", "", false);
            }
        }
    }

    /// @inheritdoc IBillboard
    function setBidURIs(
        uint256 tokenId_,
        uint256 epoch_,
        string calldata contentURI_,
        string calldata redirectURI_
    ) public {
        registry.setBidURIs(tokenId_, epoch_, msg.sender, contentURI_, redirectURI_);
    }

    /// @inheritdoc IBillboard
    function clearAuction(
        uint256 tokenId_,
        uint256 epoch_
    ) public isNotClosed(tokenId_) returns (address highestBidder, uint256 price, uint256 tax) {
        // revert if board not found
        IBillboardRegistry.Board memory _board = this.getBoard(tokenId_);
        require(_board.creator != address(0), "Board not found");

        // revert if auction is still running
        uint256 _endedAt = this.getBlockFromEpoch(_board.startedAt, epoch_ + 1, _board.epochInterval);
        require(block.number >= _endedAt, "Auction not ended");

        address _highestBidder = registry.highestBidder(tokenId_, epoch_);
        IBillboardRegistry.Bid memory _highestBid = registry.getBid(tokenId_, epoch_, _highestBidder);

        // revert if no bid
        require(_highestBid.placedAt != 0, "No bid");

        // skip if auction is already cleared
        if (_highestBid.isWon) {
            return (_highestBidder, _highestBid.price, _highestBid.tax);
        }

        address _prevOwner = registry.ownerOf(tokenId_);

        if (_highestBid.price > 0) {
            // transfer bid price to board owner (previous tenant or creator)
            registry.transferCurrencyByOperator(_prevOwner, _highestBid.price);

            // transfer bid tax to board creator's tax treasury
            (uint256 _taxAccumulated, uint256 _taxWithdrawn) = registry.taxTreasury(_board.creator);
            registry.setTaxTreasury(_board.creator, _taxAccumulated + _highestBid.tax, _taxWithdrawn);
        }

        // transfer ownership
        registry.safeTransferByOperator(_prevOwner, _highestBidder, tokenId_);

        // mark highest bid as won
        registry.setBidWon(tokenId_, epoch_, _highestBidder, true);

        // emit AuctionCleared
        registry.emitAuctionCleared(tokenId_, epoch_, _highestBidder);

        return (_highestBidder, _highestBid.price, _highestBid.tax);
    }

    /// @inheritdoc IBillboard
    function clearAuctions(
        uint256[] calldata tokenIds_,
        uint256[] calldata epochs_
    ) external returns (address[] memory highestBidders, uint256[] memory prices, uint256[] memory taxes) {
        uint256 _size = tokenIds_.length;
        address[] memory _highestBidders = new address[](_size);
        uint256[] memory _prices = new uint256[](_size);
        uint256[] memory _taxes = new uint256[](_size);

        for (uint256 i = 0; i < _size; i++) {
            (_highestBidders[i], _prices[i], _taxes[i]) = clearAuction(tokenIds_[i], epochs_[i]);
        }

        return (_highestBidders, _prices, _taxes);
    }

    /// @inheritdoc IBillboard
    function clearLastAuction(uint256 tokenId_) external returns (address highestBidder, uint256 price, uint256 tax) {
        uint256 _lastEpoch = getLatestEpoch(tokenId_) - 1;
        return clearAuction(tokenId_, _lastEpoch);
    }

    /// @inheritdoc IBillboard
    function clearLastAuctions(
        uint256[] calldata tokenIds_
    ) external returns (address[] memory highestBidders, uint256[] memory prices, uint256[] memory taxes) {
        uint256 _size = tokenIds_.length;
        address[] memory _highestBidders = new address[](_size);
        uint256[] memory _prices = new uint256[](_size);
        uint256[] memory _taxes = new uint256[](_size);

        for (uint256 i = 0; i < _size; i++) {
            (_highestBidders[i], _prices[i], _taxes[i]) = this.clearLastAuction(tokenIds_[i]);
        }

        return (_highestBidders, _prices, _taxes);
    }

    /// @inheritdoc IBillboard
    function getBid(
        uint256 tokenId_,
        uint256 epoch_,
        address bidder_
    ) external view returns (IBillboardRegistry.Bid memory bid) {
        return registry.getBid(tokenId_, epoch_, bidder_);
    }

    /// @inheritdoc IBillboard
    function getBids(
        uint256 tokenId_,
        uint256 epoch_,
        uint256 limit_,
        uint256 offset_
    ) external view returns (uint256 total, uint256 limit, uint256 offset, IBillboardRegistry.Bid[] memory bids) {
        uint256 _total = registry.getBidCount(tokenId_, epoch_);

        if (limit_ == 0 || offset_ >= _total) {
            return (_total, limit_, offset_, new IBillboardRegistry.Bid[](0));
        }

        uint256 _left = _total - offset_;
        uint256 _size = _left > limit_ ? limit_ : _left;

        bids = new IBillboardRegistry.Bid[](_size);

        for (uint256 i = 0; i < _size; i++) {
            address _bidder = registry.bidders(tokenId_, epoch_, offset_ + i);
            bids[i] = registry.getBid(tokenId_, epoch_, _bidder);
        }

        return (_total, limit_, offset_, bids);
    }

    /// @inheritdoc IBillboard
    function getBidderBids(
        uint256 tokenId_,
        address bidder_,
        uint256 limit_,
        uint256 offset_
    )
        external
        view
        returns (
            uint256 total,
            uint256 limit,
            uint256 offset,
            IBillboardRegistry.Bid[] memory bids,
            uint256[] memory epochs
        )
    {
        uint256 _total = registry.getBidderBidCount(tokenId_, bidder_);

        if (limit_ == 0 || offset_ >= _total) {
            return (_total, limit_, offset_, new IBillboardRegistry.Bid[](0), new uint256[](0));
        }

        uint256 _left = _total - offset_;
        uint256 _size = _left > limit_ ? limit_ : _left;

        (bids, epochs) = _getBidsAndEpochs(tokenId_, bidder_, offset_, _size);

        return (_total, limit_, offset_, bids, epochs);
    }

    function _getBidsAndEpochs(
        uint256 tokenId_,
        address bidder_,
        uint256 offset_,
        uint256 size_
    ) internal view returns (IBillboardRegistry.Bid[] memory bids, uint256[] memory epochs) {
        bids = new IBillboardRegistry.Bid[](size_);
        epochs = new uint256[](size_);

        for (uint256 i = 0; i < size_; i++) {
            uint256 _epoch = registry.bidderBids(tokenId_, bidder_, offset_ + i);
            bids[i] = registry.getBid(tokenId_, _epoch, bidder_);
            epochs[i] = _epoch;
        }
    }

    /// @inheritdoc IBillboard
    function withdrawBid(uint256 tokenId_, uint256 epoch_, address bidder_) external {
        bool _isClosed = closed[tokenId_];

        // revert if board not found
        IBillboardRegistry.Board memory _board = this.getBoard(tokenId_);
        require(_board.creator != address(0), "Board not found");

        // revert if auction is not ended
        uint256 _endedAt = this.getBlockFromEpoch(_board.startedAt, epoch_ + 1, _board.epochInterval);
        require(_isClosed || block.number >= _endedAt, "Auction not ended");

        // revert if auction is not cleared
        address _highestBidder = registry.highestBidder(tokenId_, epoch_);
        IBillboardRegistry.Bid memory _highestBid = registry.getBid(tokenId_, epoch_, _highestBidder);
        require(_isClosed || _highestBid.isWon, "Auction not cleared");

        IBillboardRegistry.Bid memory _bid = registry.getBid(tokenId_, epoch_, bidder_);
        uint256 amount = _bid.price + _bid.tax;

        require(_bid.placedAt != 0, "Bid not found");
        require(!_bid.isWithdrawn, "Bid already withdrawn");
        require(!_bid.isWon, "Bid already won");
        require(amount > 0, "Zero amount");

        // set bid.isWithdrawn to true first to prevent reentrancy
        registry.setBidWithdrawn(tokenId_, epoch_, bidder_, true);

        // transfer bid price and tax back to the bidder
        registry.transferCurrencyByOperator(bidder_, amount);
    }

    /// @inheritdoc IBillboard
    function getEpochFromBlock(
        uint256 startedAt_,
        uint256 block_,
        uint256 epochInterval_
    ) public pure returns (uint256 epoch) {
        return (block_ - startedAt_) / epochInterval_;
    }

    /// @inheritdoc IBillboard
    function getBlockFromEpoch(
        uint256 startedAt_,
        uint256 epoch_,
        uint256 epochInterval_
    ) public pure returns (uint256 blockNumber) {
        return startedAt_ + (epoch_ * epochInterval_);
    }

    /// @inheritdoc IBillboard
    function getLatestEpoch(uint256 tokenId_) public view returns (uint256 epoch) {
        IBillboardRegistry.Board memory _board = registry.getBoard(tokenId_);
        return this.getEpochFromBlock(_board.startedAt, block.number, _board.epochInterval);
    }

    //////////////////////////////
    /// Tax & Withdraw
    //////////////////////////////

    /// @inheritdoc IBillboard
    function getTaxRate(uint256 tokenId_) external view returns (uint256 taxRate) {
        return registry.getBoard(tokenId_).taxRate;
    }

    function calculateTax(uint256 tokenId_, uint256 amount_) public view returns (uint256 tax) {
        tax = (amount_ * this.getTaxRate(tokenId_)) / 1000;
    }

    /// @inheritdoc IBillboard
    function withdrawTax(address creator_) external returns (uint256 tax) {
        (uint256 _taxAccumulated, uint256 _taxWithdrawn) = registry.taxTreasury(creator_);

        uint256 amount = _taxAccumulated - _taxWithdrawn;

        require(amount > 0, "Zero amount");

        // set taxTreasury.withdrawn to taxTreasury.accumulated first
        // to prevent reentrancy
        registry.setTaxTreasury(creator_, _taxAccumulated, _taxAccumulated);

        // transfer tax to the owner
        registry.transferCurrencyByOperator(creator_, amount);

        // emit TaxWithdrawn
        registry.emitTaxWithdrawn(creator_, amount);

        return amount;
    }

    //////////////////////////////
    /// ERC721 related
    //////////////////////////////

    /// @inheritdoc IBillboard
    function _tokenURI(uint256 tokenId_) external view returns (string memory uri) {
        require(msg.sender == address(registry), "Unauthorized");
        require(registry.exists(tokenId_), "Token not found");

        IBillboardRegistry.Board memory _board = registry.getBoard(tokenId_);

        string memory tokenName = string(abi.encodePacked(registry.name(), " #", Strings.toString(tokenId_)));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        tokenName,
                        '", "description": "',
                        _board.description,
                        '", "location": "',
                        _board.location,
                        '", "image": "',
                        _board.imageURI,
                        '"}'
                    )
                )
            )
        );

        uri = string(abi.encodePacked("data:application/json;base64,", json));
    }
}
