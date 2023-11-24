//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "./BillboardRegistry.sol";
import "./IBillboard.sol";
import "./IBillboardRegistry.sol";

contract Billboard is IBillboard {
    BillboardRegistry public registry;

    // access control
    bool public isOpened = false;
    address public admin;
    mapping(address => bool) public whitelist;

    constructor(address payable registry_, uint256 taxRate_, string memory name_, string memory symbol_) {
        admin = msg.sender;
        whitelist[msg.sender] = true;

        // deploy operator only
        if (registry_ != address(0)) {
            registry = BillboardRegistry(registry_);
        }
        // deploy operator and registry
        else {
            registry = new BillboardRegistry(address(this), taxRate_, name_, symbol_);
        }
    }

    //////////////////////////////
    /// Modifiers
    //////////////////////////////

    modifier isFromAdmin() {
        require(msg.sender == admin, "Admin");
        _;
    }

    modifier isFromWhitelist() {
        require(whitelist[msg.sender], "Whitelist");
        _;
    }

    modifier isFromBoardCreator(uint256 tokenId_) {
        IBillboardRegistry.Board memory _board = registry.getBoard(tokenId_);
        require(_board.creator == msg.sender, "Creator");
        _;
    }

    modifier isFromBoardTenant(uint256 tokenId_) {
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
    function setIsOpened(bool value_) external isFromAdmin {
        isOpened = value_;
    }

    /// @inheritdoc IBillboard
    function addToWhitelist(address value_) external isFromAdmin {
        whitelist[value_] = true;
    }

    /// @inheritdoc IBillboard
    function removeFromWhitelist(address value_) external isFromAdmin {
        whitelist[value_] = false;
    }

    //////////////////////////////
    /// Board
    //////////////////////////////

    /// @inheritdoc IBillboard
    function mintBoard(address to_) external returns (uint256 tokenId) {
        require(isOpened || whitelist[msg.sender], "Whitelist");

        tokenId = registry.mintBoard(to_);
    }

    /// @inheritdoc IBillboard
    function getBoard(uint256 tokenId_) external view returns (IBillboardRegistry.Board memory board) {
        return registry.getBoard(tokenId_);
    }

    /// @inheritdoc IBillboard
    function setBoardName(uint256 tokenId_, string calldata name_) external isFromBoardCreator(tokenId_) {
        registry.setBoardName(tokenId_, name_);
    }

    /// @inheritdoc IBillboard
    function setBoardDescription(uint256 tokenId_, string calldata description_) external isFromBoardCreator(tokenId_) {
        registry.setBoardDescription(tokenId_, description_);
    }

    /// @inheritdoc IBillboard
    function setBoardLocation(uint256 tokenId_, string calldata location_) external isFromBoardCreator(tokenId_) {
        registry.setBoardLocation(tokenId_, location_);
    }

    /// @inheritdoc IBillboard
    function setBoardContentURI(uint256 tokenId_, string calldata contentURI_) external isFromBoardTenant(tokenId_) {
        registry.setBoardContentURI(tokenId_, contentURI_);
    }

    /// @inheritdoc IBillboard
    function setBoardRedirectURI(uint256 tokenId_, string calldata redirectURI_) external isFromBoardTenant(tokenId_) {
        registry.setBoardRedirectURI(tokenId_, redirectURI_);
    }

    //////////////////////////////
    /// Auction
    //////////////////////////////

    /// @inheritdoc IBillboard
    function getAuction(
        uint256 tokenId_,
        uint256 auctionId_
    ) external view returns (IBillboardRegistry.Auction memory auction) {
        auction = registry.getAuction(tokenId_, auctionId_);
    }

    /// @inheritdoc IBillboard
    function clearAuction(uint256 tokenId_) public {
        // revert if board not found
        IBillboardRegistry.Board memory _board = registry.getBoard(tokenId_);
        require(_board.creator != address(0), "Board not found");

        // revert if it's a new board
        uint256 _nextAuctionId = registry.nextBoardAuctionId(tokenId_);
        require(_nextAuctionId != 0, "Auction not found");

        IBillboardRegistry.Auction memory _nextAuction = registry.getAuction(tokenId_, _nextAuctionId);

        // revert if auction is still running
        require(block.timestamp >= _nextAuction.endAt, "Auction not ended");

        // reclaim ownership to board creator if no auction
        address _prevOwner = registry.ownerOf(tokenId_);
        if (_nextAuction.startAt == 0 && _prevOwner != _board.creator) {
            registry.safeTransferByOperator(_prevOwner, _board.creator, tokenId_);
            return;
        }

        _clearAuction(tokenId_, _board.creator, _nextAuctionId);
    }

    /// @inheritdoc IBillboard
    function clearAuctions(uint256[] calldata tokenIds_) external {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            clearAuction(tokenIds_[i]);
        }
    }

    function _clearAuction(uint256 tokenId_, address boardCreator_, uint256 nextAuctionId_) private {
        IBillboardRegistry.Auction memory _nextAuction = registry.getAuction(tokenId_, nextAuctionId_);

        // skip if auction is already cleared
        if (_nextAuction.leaseEndAt != 0) {
            return;
        }

        address _prevOwner = registry.ownerOf(tokenId_);

        IBillboardRegistry.Bid memory _highestBid = registry.getBid(
            tokenId_,
            nextAuctionId_,
            _nextAuction.highestBidder
        );

        if (_highestBid.price > 0) {
            // transfer bid price to board owner (previous tenant or creator)
            registry.transferAmount(_prevOwner, _highestBid.price);

            // transfer bid tax to board creator's tax treasury
            (uint256 _taxAccumulated, uint256 _taxWithdrawn) = registry.taxTreasury(boardCreator_);
            registry.setTaxTreasury(boardCreator_, _taxAccumulated + _highestBid.tax, _taxWithdrawn);
        }

        // transfer ownership
        registry.safeTransferByOperator(_prevOwner, _nextAuction.highestBidder, tokenId_);

        // mark highest bid as won
        registry.setBidWon(tokenId_, nextAuctionId_, _nextAuction.highestBidder, true);

        // set auction lease
        uint64 leaseStartAt = uint64(block.timestamp);
        uint64 leaseEndAt = uint64(leaseStartAt + registry.leaseTerm());
        registry.setAuctionLease(tokenId_, nextAuctionId_, leaseStartAt, leaseEndAt);

        // emit AuctionCleared
        registry.emitAuctionCleared(tokenId_, nextAuctionId_, _nextAuction.highestBidder, leaseStartAt, leaseEndAt);
    }

    /// @inheritdoc IBillboard
    function placeBid(uint256 tokenId_, uint256 amount_) external payable isFromWhitelist {
        IBillboardRegistry.Board memory _board = registry.getBoard(tokenId_);
        require(_board.creator != address(0), "Board not found");

        uint256 _nextAuctionId = registry.nextBoardAuctionId(tokenId_);
        IBillboardRegistry.Auction memory _nextAuction = registry.getAuction(tokenId_, _nextAuctionId);

        // if it's a new board without next auction,
        // create new auction and new bid first,
        // then clear auction and transfer ownership to the bidder immediately.
        if (_nextAuction.startAt == 0) {
            uint256 _auctionId = _newAuctionAndBid(tokenId_, amount_, uint64(block.timestamp));
            _clearAuction(tokenId_, _board.creator, _auctionId);
            return;
        }

        // if next auction is ended,
        // clear auction first,
        // then create new auction and new bid
        if (block.timestamp >= _nextAuction.endAt) {
            _clearAuction(tokenId_, _board.creator, _nextAuctionId);
            _newAuctionAndBid(tokenId_, amount_, uint64(block.timestamp + registry.leaseTerm()));
            return;
        }
        // if next auction is not ended,
        // push new bid to next auction
        else {
            require(registry.getBid(tokenId_, _nextAuctionId, msg.sender).placedAt == 0, "Bid already placed");

            uint256 _tax = calculateTax(amount_);
            registry.newBid(tokenId_, _nextAuctionId, msg.sender, amount_, _tax);

            _lockBidPriceAndTax(amount_ + _tax);
        }
    }

    function _newAuctionAndBid(uint256 tokenId_, uint256 amount_, uint64 endAt_) private returns (uint256 auctionId) {
        uint64 _startAt = uint64(block.timestamp);
        uint256 _tax = calculateTax(amount_);

        auctionId = registry.newAuction(tokenId_, _startAt, endAt_);

        registry.newBid(tokenId_, auctionId, msg.sender, amount_, _tax);

        _lockBidPriceAndTax(amount_ + _tax);
    }

    function _lockBidPriceAndTax(uint256 amount_) private {
        // transfer bid price and tax to the registry
        (bool _success, ) = address(registry).call{value: amount_}("");
        require(_success, "Transfer failed");

        // refund if overpaid
        uint256 _overpaid = msg.value - amount_;
        if (_overpaid > 0) {
            (bool _refundSuccess, ) = msg.sender.call{value: _overpaid}("");
            require(_refundSuccess, "Transfer failed");
        }
    }

    /// @inheritdoc IBillboard
    function getBid(
        uint256 tokenId_,
        uint256 auctionId_,
        address bidder_
    ) external view returns (IBillboardRegistry.Bid memory bid) {
        return registry.getBid(tokenId_, auctionId_, bidder_);
    }

    /// @inheritdoc IBillboard
    function getBids(
        uint256 tokenId_,
        uint256 auctionId_,
        uint256 limit_,
        uint256 offset_
    ) external view returns (uint256 total, uint256 limit, uint256 offset, IBillboardRegistry.Bid[] memory bids) {
        uint256 _total = registry.getBidCount(tokenId_, auctionId_);

        if (limit_ == 0) {
            return (_total, limit_, offset_, new IBillboardRegistry.Bid[](0));
        }

        if (offset_ >= _total) {
            return (_total, limit_, offset_, new IBillboardRegistry.Bid[](0));
        }

        uint256 _left = _total - offset_;
        uint256 _size = _left > limit_ ? limit_ : _left;

        IBillboardRegistry.Bid[] memory _bids = new IBillboardRegistry.Bid[](_size);

        for (uint256 i = 0; i < _size; i++) {
            address _bidder = registry.auctionBidders(tokenId_, auctionId_, offset_ + i);
            _bids[i] = registry.getBid(tokenId_, auctionId_, _bidder);
        }

        return (_total, limit_, offset_, _bids);
    }

    //////////////////////////////
    /// Tax & Withdraw
    //////////////////////////////

    /// @inheritdoc IBillboard
    function getTaxRate() external view returns (uint256 taxRate) {
        return registry.taxRate();
    }

    /// @inheritdoc IBillboard
    function setTaxRate(uint256 taxRate_) external isFromAdmin {
        registry.setTaxRate(taxRate_);
    }

    function calculateTax(uint256 amount_) public view returns (uint256 tax) {
        tax = (amount_ * registry.taxRate() * registry.leaseTerm()) / 1 days / 100;
    }

    /// @inheritdoc IBillboard
    function withdrawTax() external {
        (uint256 _taxAccumulated, uint256 _taxWithdrawn) = registry.taxTreasury(msg.sender);

        uint256 amount = _taxAccumulated - _taxWithdrawn;

        require(amount > 0, "Zero amount");

        // transfer tax to the owner
        registry.transferAmount(msg.sender, amount);

        // set taxTreasury.withdrawn to taxTreasury.accumulated
        registry.setTaxTreasury(msg.sender, _taxAccumulated, _taxAccumulated);

        // emit TaxWithdrawn
        registry.emitTaxWithdrawn(msg.sender, amount);
    }

    /// @inheritdoc IBillboard
    function withdrawBid(uint256 tokenId_, uint256 auctionId_) external {
        // revert if auction is still running
        IBillboardRegistry.Auction memory _auction = registry.getAuction(tokenId_, auctionId_);
        require(block.timestamp >= _auction.endAt, "Auction not ended");

        // revert if auction is not cleared
        require(_auction.leaseEndAt != 0, "Auction not cleared");

        IBillboardRegistry.Bid memory _bid = registry.getBid(tokenId_, auctionId_, msg.sender);
        uint256 amount = _bid.price + _bid.tax;

        require(_bid.placedAt != 0, "Bid not found");
        require(!_bid.isWithdrawn, "Bid already withdrawn");
        require(!_bid.isWon, "Bid already won");
        require(amount > 0, "Zero amount");

        // transfer bid price and tax back to the bidder
        registry.transferAmount(msg.sender, amount);

        // set bid.isWithdrawn to true
        registry.setBidWithdrawn(tokenId_, auctionId_, msg.sender, true);

        // emit BidWithdrawn
        registry.emitBidWithdrawn(tokenId_, auctionId_, msg.sender, _bid.price, _bid.tax);
    }
}
