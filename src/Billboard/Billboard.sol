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

    constructor(address registry_, uint256 taxRate_, string memory name_, string memory symbol_) {
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
        if (whitelist[msg.sender] != true) {
            revert Unauthorized("whitelist");
        }
        _;
    }

    modifier isFromBoardCreator(uint256 tokenId_) {
        (address _boardCreator, , , , , , ) = registry.boards(tokenId_);
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
        if (isOpened || whitelist[msg.sender] == true) {
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
        return registry.getAuction(tokenId_, auctionId_);
    }

    /// @inheritdoc IBillboard
    function clearAuction(uint256 tokenId_) external {
        (address _boardCreator, , , , , , ) = registry.boards(tokenId_);
        if (_boardCreator == address(0)) revert BoardNotFound();

        uint256 _nextAuctionId = registry.nextBoardAuctionId(tokenId_);
        if (_nextAuctionId == 0) revert AuctionNotFound();

        IBillboardRegistry.Auction memory _nextAuction = registry.getAuction(tokenId_, _nextAuctionId);

        // reclaim ownership to board creator if no auction
        if (_nextAuction.tokenId == 0) {
            registry.safeTransferByOperator(msg.sender, _boardCreator, tokenId_);
            return;
        }

        if (block.timestamp < _nextAuction.endAt) revert AuctionNotEnded();

        IBillboardRegistry.Bid memory _highestBid = registry.getBid(
            tokenId_,
            _nextAuctionId,
            _nextAuction.highestBidder
        );
        if (_highestBid.price > 0) {
            // transfer bid price to board owner (previous tenant or creator)
            registry.transferAmount(registry.ownerOf(tokenId_), _highestBid.price);

            // transfer bid tax to board creator's tax treasury
            (, uint256 _taxAccumulated, uint256 _taxWithdrawn) = registry.taxTreasury(_boardCreator);
            registry.setTaxTreasury(_boardCreator, _taxAccumulated + _highestBid.tax, _taxWithdrawn);
        }

        // transfer ownership
        registry.safeTransferByOperator(registry.ownerOf(tokenId_), _nextAuction.highestBidder, tokenId_);

        // mark highest bid as won
        registry.setBidWon(tokenId_, _nextAuctionId, _nextAuction.highestBidder, true);

        // set auction lease
        uint256 leaseStartAt = block.timestamp;
        uint256 leaseEndAt = block.timestamp + 14 days;
        registry.setAuctionLease(tokenId_, _nextAuctionId, leaseStartAt, leaseEndAt);

        // update Board.auctionId
        registry.setBoardAuctionId(tokenId_, _nextAuctionId);
    }

    /// @inheritdoc IBillboard
    function placeBid(uint256 tokenId_, uint256 amount_) external isFromWhitelist {
        (address _boardCreator, , , , , , ) = registry.boards(tokenId_);
        if (_boardCreator == address(0)) revert BoardNotFound();

        uint256 _nextAuctionId = registry.nextBoardAuctionId(tokenId_);
        IBillboardRegistry.Auction memory _nextAuction = registry.getAuction(tokenId_, _nextAuctionId);

        // TODO: check if current address already has bidded
        // TODO: transfer ETH to registry
        // TODO: set highestBidder

        // create new auction and new bid if no next auction
        if (_nextAuction.tokenId == 0) {
            _newAuctionAndBid(tokenId_, amount_);
            return;
        }

        // clear auction first if next auction is ended, then create new auction and new bid
        if (block.timestamp >= _nextAuction.endAt) {
            this.clearAuction(tokenId_);
            _newAuctionAndBid(tokenId_, amount_);
            return;
        } else {
            // push new bid to next auction
            registry.newBid(tokenId_, _nextAuctionId, msg.sender, amount_, calculateTax(amount_));
        }
    }

    function _newAuctionAndBid(uint256 tokenId_, uint256 amount_) private {
        uint256 _startAt = block.timestamp;
        uint256 _endAt = block.timestamp + 14 days;
        uint256 _auctionId = registry.newAuction(tokenId_, _startAt, _endAt);
        registry.newBid(tokenId_, _auctionId, msg.sender, amount_, calculateTax(amount_));
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
        return (amount_ * registry.taxRate()) / 100;
    }

    /// @inheritdoc IBillboard
    function withdrawTax() external {
        (, uint256 _taxAccumulated, uint256 _taxWithdrawn) = registry.taxTreasury(msg.sender);

        uint256 amount = _taxAccumulated - _taxWithdrawn;

        if (amount <= 0) revert WithdrawFailed();

        // transfer tax to the owner
        registry.transferAmount(msg.sender, amount);

        // set taxTreasury.withdrawn to taxTreasury.accumulated
        registry.setTaxTreasury(msg.sender, _taxAccumulated, _taxAccumulated);
    }

    /// @inheritdoc IBillboard
    function withdrawBid(uint256 tokenId_, uint256 auctionId_) external {
        IBillboardRegistry.Bid memory _bid = registry.getBid(tokenId_, auctionId_, msg.sender);
        uint256 amount = _bid.price + _bid.tax;

        if (_bid.isWithdrawn) revert WithdrawFailed();
        if (amount <= 0) revert WithdrawFailed();

        // transfer bid price and tax back to the bidder
        registry.transferAmount(msg.sender, amount);

        // set bid.isWithdrawn to true
        registry.setBidWithdrawn(tokenId_, auctionId_, msg.sender, true);
    }
}
