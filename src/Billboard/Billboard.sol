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

    constructor() {
        admin = msg.sender;
        whitelist[msg.sender] = true;
    }

    //////////////////////////////
    /// Modifiers
    //////////////////////////////

    modifier isValidAddress(address value_) {
        if (value_ == address(0)) {
            revert InvalidAddress();
        }
        _;
    }

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
        if (msg.sender != boards[tokenId_].creator) {
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
    function upgradeRegistry(address contract_) external isValidAddress(contract_) isAdmin(msg.sender) {
        registry = BillboardRegistry(contract_);
    }

    /// @inheritdoc IBillboardRegistry
    function setIsOpened(bool value_, address sender_) external isAdmin(sender_) {
        isOpened = value_;
    }

    /// @inheritdoc IBillboardRegistry
    function addToWhitelist(address value_, address sender_) external isAdmin(sender_) {
        whitelist[value_] = true;
    }

    /// @inheritdoc IBillboardRegistry
    function removeFromWhitelist(address value_, address sender_) external isAdmin(sender_) {
        whitelist[value_] = false;
    }

    //////////////////////////////
    /// Board
    //////////////////////////////

    /// @inheritdoc IBillboard
    function mintBoard(address to_) external isValidAddress(to_) isFromWhitelist {
        if (!isOpened) {
            revert MintClosed();
        }

        registry.mint(to_);
    }

    /// @inheritdoc IBillboard
    function getBoard(uint256 tokenId_) external view returns (IBillboardRegistry.Board memory board) {
        return registry.boards[tokenId_];
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
    function setBoardContentUri(uint256 tokenId_, string calldata contentUri_) external isFromBoardTenant(tokenId_) {
        registry.setBoardContentUri(tokenId_, contentUri_);
    }

    /// @inheritdoc IBillboard
    function setBoardRedirectUri(uint256 tokenId_, string calldata redirectUri_) external isFromBoardTenant(tokenId_) {
        registry.setBoardRedirectUri(tokenId_, redirectUri_);
    }

    //////////////////////////////
    /// Auction
    //////////////////////////////

    /// @inheritdoc IBillboard
    function getAuction(
        uint256 tokenId_,
        uint256 auctionId_
    ) external view returns (IBillboardRegistry.Auction memory auction) {
        return registry.boardAuctions[tokenId_][auctionId_];
    }

    /// @inheritdoc IBillboard
    function clearAuction(uint256 tokenId_) external {
        IBillboardRegistry.Board board = registry.boards[tokenId_];
        if (!board) revert BoardNotFound();

        uint256 nextAuctionId = registry.nextBoardAuctionId[tokenId_];
        if (nextAuctionId == 0) revert AuctionNotFound();

        IBillboardRegistry.Auction nextAuction = registry.boardAuctions[tokenId_][nextAuctionId];

        // reclaim ownership to board creator if no auction
        if (!nextAuction) {
            registry.safeTransferByOperator(msg.sender, board.creator, tokenId_);
            return;
        }

        if (block.timestamp < nextAuction.endAt) revert AuctionNotEnded();

        IBillboardRegistry.Bid highestBid = nextAuction.bids[nextAuction.highestBidder];
        if (highestBid.price > 0) {
            // transfer bid price to board owner (previous tenant or creator)
            registry.transferAmount(registry.ownerOf(tokenId_), highestBid.price);

            // transfer bid tax to board creator's tax treasury
            (uint256 taxAccumulated, uint256 taxWithdrawn) = registry.taxTreasury[recipient];
            registry.setTaxTreasury(board.creator, taxAccumulated + highestBid.tax, taxWithdrawn);
        }

        // transfer ownership
        registry.safeTransferByOperator(registry.ownerOf(tokenId_), nextAuction.highestBidder, tokenId_);

        // mark highest bid as won
        highestBid.isWon = true;

        // set auction lease
        uint256 leaseStartAt = block.timestamp;
        uint256 leaseEndAt = block.timestamp + 14 days;
        registry.setAuctionLease(tokenId_, nextAuctionId, leaseStartAt, leaseEndAt);

        // update Board.auctionId
        registry.setBoardAuctionId(tokenId_, nextAuctionId);
    }

    /// @inheritdoc IBillboard
    function placeBid(uint256 tokenId_, uint256 amount_) external isFromWhitelist {
        IBillboardRegistry.Board board = registry.boards[tokenId_];
        if (!board) revert BoardNotFound();

        uint256 nextAuctionId = registry.nextBoardAuctionId[tokenId_];
        IBillboardRegistry.Auction nextAuction = registry.boardAuctions[tokenId_][nextAuctionId];

        // create new auction and new bid if no next auction
        if (!nextAuction) {
            _newAuctionAndBid(tokenId_, amount_);
            return;
        }

        // clear auction first if next auction is ended, then create new auction and new bid
        if (block.timestamp >= nextAuction.endAt) {
            clearAuction(tokenId_);
            _newAuctionAndBid(tokenId_, amount_);
            return;
        } else {
            // push new bid to next auction
            registry.newBid(tokenId_, nextAuctionId, msg.sender, amount_, calculateTax(amount_));
        }
    }

    function _newAuctionAndBid(uint256 tokenId_, uint256 amount_) private {
        uint256 startAt = block.timestamp;
        uint256 endAt = block.timestamp + 14 days;
        uint256 auctionId = registry.newAuction(tokenId_, startAt, endAt);
        registry.newBid(tokenId_, auctionId, msg.sender, amount_, calculateTax(amount_));
    }

    /// @inheritdoc IBillboard
    function getBid(uint256 tokenId_, address bidder_) external view returns (IBillboardRegistry.Bid memory bid) {
        return registry.getBid(tokenId_, bidder_);
    }

    /// @inheritdoc IBillboard
    function getBids(
        uint256 tokenId_,
        uint256 auctionId_,
        uint256 limit_,
        uint256 offset_
    ) external view returns (uint256 total, uint256 limit, uint256 offset, IBillboardRegistry.Bid[] memory bids) {
        IBillboardRegistry.Auction _auction = registry.boardAuctions[tokenId_][auctionId_];
        uint256 _total = _auction.bids.length;

        if (limit_ == 0) {
            return (_total, limit_, offset_, new IBillboardRegistry.Bid[](0));
        }

        if (offset_ >= _total) {
            return (_total, limit_, offset_, new IBillboardRegistry.Bid[](0));
        }

        uint256 left = _total - offset_;
        uint256 size = left > limit_ ? limit_ : left;

        IBillboardRegistry.Bid[] memory _bids = new IBillboardRegistry.Bid[](size);

        for (uint256 i = 0; i < size; i++) {
            _bids[i] = _auction.bids[offset_ + i];
        }

        return (_total, limit_, offset_, _bids);
    }

    //////////////////////////////
    /// Tax & Withdraw
    //////////////////////////////

    /// @inheritdoc IBillboard
    function getTaxRate() external view returns (uint256 taxRate) {
        return registry.taxRate;
    }

    /// @inheritdoc IBillboard
    function setTaxRate(uint256 taxRate_) external isFromAdmin {
        registry.setTaxRate(taxRate_);
    }

    function calculateTax(uint256 amount_) public view returns (uint256 tax) {
        return (amount_ * registry.taxRate) / 100;
    }

    /// @inheritdoc IBillboard
    function withdrawTax() external {
        IBillboardRegistry.TaxTreasury taxTreasury = registry.taxTreasury[msg.sender];

        uint256 amount = taxTreasury.accumulated - taxTreasury.withdrawn;

        if (amount <= 0) revert WithdrawFailed();

        // transfer tax to the owner
        registry.transferAmount(msg.sender, amount);

        // set taxTreasury.withdrawn to taxTreasury.accumulated
        registry.setTaxTreasury(msg.sender, taxTreasury.accumulated, taxTreasury.accumulated);
    }

    /// @inheritdoc IBillboard
    function withdrawBid(uint256 tokenId_, uint256 auctionId_) external {
        IBillboardRegistry.Bid bid = boardAuctions[tokenId_][auctionId_].bids[msg.sender];
        uint256 amount = bid.price + bid.tax;

        if (bid.isWithdrawn) revert WithdrawFailed();
        if (amount <= 0) revert WithdrawFailed();

        // transfer bid price and tax back to the bidder
        registry.transferAmount(msg.sender, amount);

        // set bid.isWithdrawn to true
        registry.setBid(tokenId_, auctionId_, msg.sender, false, true);
    }
}
