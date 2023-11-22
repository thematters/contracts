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
        if (msg.sender != admin) {
            revert Unauthorized("admin");
        }
        _;
    }

    modifier isFromWhitelist() {
        if (!whitelist[msg.sender]) {
            revert Unauthorized("whitelist");
        }
        _;
    }

    modifier isFromBoardCreator(uint256 tokenId_) {
        (address _boardCreator, , , , , ) = registry.boards(tokenId_);
        if (_boardCreator != msg.sender) {
            revert Unauthorized("creator");
        }
        _;
    }

    modifier isFromBoardTenant(uint256 tokenId_) {
        if (msg.sender != registry.ownerOf(tokenId_)) {
            revert Unauthorized("tenant");
        }
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
        if (isOpened || whitelist[msg.sender]) {
            tokenId = registry.mintBoard(to_);
        } else {
            revert Unauthorized("whitelist");
        }
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
        (address _boardCreator, , , , , ) = registry.boards(tokenId_);
        if (_boardCreator == address(0)) revert BoardNotFound();

        // revert if it's a new board
        uint256 _nextAuctionId = registry.nextBoardAuctionId(tokenId_);
        if (_nextAuctionId == 0) revert AuctionNotFound();

        IBillboardRegistry.Auction memory _nextAuction = registry.getAuction(tokenId_, _nextAuctionId);

        // revert if auction is still running
        if (block.timestamp < _nextAuction.endAt) revert AuctionNotEnded();

        // reclaim ownership to board creator if no auction
        address _prevOwner = registry.ownerOf(tokenId_);
        if (_nextAuction.startAt == 0 && _prevOwner != _boardCreator) {
            registry.safeTransferByOperator(_prevOwner, _boardCreator, tokenId_);
            return;
        }

        _clearAuction(tokenId_, _boardCreator, _nextAuctionId);
    }

    /// @inheritdoc IBillboard
    function clearAuctions(uint256[] calldata tokenIds_) external {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            clearAuction(tokenIds_[i]);
        }
    }

    function _clearAuction(uint256 tokenId_, address boardCreator_, uint256 nextAuctionId_) private {
        IBillboardRegistry.Auction memory _nextAuction = registry.getAuction(tokenId_, nextAuctionId_);
        IBillboardRegistry.Bid memory _highestBid = registry.getBid(
            tokenId_,
            nextAuctionId_,
            _nextAuction.highestBidder
        );

        address _prevOwner = registry.ownerOf(tokenId_);
        if (_highestBid.price > 0) {
            // transfer bid price to board owner (previous tenant or creator)
            registry.transferAmount(_prevOwner, _highestBid.price);

            // transfer bid tax to board creator's tax treasury
            (, uint256 _taxAccumulated, uint256 _taxWithdrawn) = registry.taxTreasury(boardCreator_);
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
        (address _boardCreator, , , , , ) = registry.boards(tokenId_);
        if (_boardCreator == address(0)) revert BoardNotFound();

        uint256 _nextAuctionId = registry.nextBoardAuctionId(tokenId_);
        IBillboardRegistry.Auction memory _nextAuction = registry.getAuction(tokenId_, _nextAuctionId);

        // if it's a new board without next auction,
        // create new auction and new bid first,
        // then clear auction and transfer ownership to the bidder immediately.
        if (_nextAuction.startAt == 0) {
            uint256 _auctionId = _newAuctionAndBid(tokenId_, amount_, uint64(block.timestamp));
            _clearAuction(tokenId_, _boardCreator, _auctionId);
            return;
        }

        // if next auction is ended,
        // clear auction first,
        // then create new auction and new bid
        if (block.timestamp >= _nextAuction.endAt) {
            _clearAuction(tokenId_, _boardCreator, _nextAuctionId);
            _newAuctionAndBid(tokenId_, amount_, uint64(block.timestamp + registry.leaseTerm()));
            return;
        }
        // if next auction is not ended,
        // push new bid to next auction
        else {
            if (registry.getBid(tokenId_, _nextAuctionId, msg.sender).placedAt != 0) {
                revert BidAlreadyPlaced();
            }

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
        (bool _success, ) = address(registry).call{value: amount_}("");
        if (!_success) {
            revert TransferFailed();
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
        (, uint256 _taxAccumulated, uint256 _taxWithdrawn) = registry.taxTreasury(msg.sender);

        uint256 amount = _taxAccumulated - _taxWithdrawn;

        if (amount <= 0) revert WithdrawFailed("zero amount");

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
        if (block.timestamp < _auction.endAt) revert AuctionNotEnded();

        // revert if auction is not cleared
        if (_auction.leaseEndAt == 0) revert WithdrawFailed("auction not cleared");

        IBillboardRegistry.Bid memory _bid = registry.getBid(tokenId_, auctionId_, msg.sender);
        uint256 amount = _bid.price + _bid.tax;

        if (_bid.placedAt == 0) revert BidNotFound();
        if (_bid.isWithdrawn) revert WithdrawFailed("withdrawn");
        if (_bid.isWon) revert WithdrawFailed("won");
        if (amount <= 0) revert WithdrawFailed("zero amount");

        // transfer bid price and tax back to the bidder
        registry.transferAmount(msg.sender, amount);

        // set bid.isWithdrawn to true
        registry.setBidWithdrawn(tokenId_, auctionId_, msg.sender, true);

        // emit BidWithdrawn
        registry.emitBidWithdrawn(tokenId_, auctionId_, msg.sender, _bid.price, _bid.tax);
    }
}
