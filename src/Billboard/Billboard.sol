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

    modifier isFromBoardCreator(uint256 tokenId_) {
        if (msg.sender != boards[tokenId_].creator) {
            revert Unauthorized("creator");
        }
        _;
    }

    modifier isFromBoardTenant(uint256 tokenId_) {
        if (msg.sender != _ownerOf(tokenId_)) {
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
    function mintBoard(address to_) external isValidAddress(to_) {
        if (!isOpened) {
            revert MintClosed();
        }

        if (!whitelist[msg.sender]) {
            revert Unauthorized("whitelist");
        }

        registry.mint(to_);
    }

    /// @inheritdoc IBillboard
    function getBoard(uint256 tokenId_) external view returns (IBillboardRegistry.Board memory board) {
        return registry.boards[tokenId_];
    }

    /// @inheritdoc IBillboard
    function setBoardName(uint256 tokenId_, string calldata name_) external isFromBoardCreator {
        registry.setBoardName(tokenId_, name_);
    }

    /// @inheritdoc IBillboard
    function setBoardDescription(uint256 tokenId_, string calldata description_) external isFromBoardCreator {
        registry.setBoardDescription(tokenId_, description_);
    }

    /// @inheritdoc IBillboard
    function setBoardLocation(uint256 tokenId_, string calldata location_) external isFromBoardCreator {
        registry.setBoardLocation(tokenId_, location_);
    }

    /// @inheritdoc IBillboard
    function setBoardLocation(uint256 tokenId_, string calldata contentUri_) external isFromBoardCreator {
        registry.setBoardContentUri(tokenId_, contentUri_);
    }

    /// @inheritdoc IBillboard
    function setBoardLocation(uint256 tokenId_, string calldata redirectUri_) external isFromBoardCreator {
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
        registry.clearAuction(tokenId_);

        // TODO update board data
    }

    /// @inheritdoc IBillboard
    function placeBid(uint256 tokenId_, uint256 amount_) external {
        registry.placeBid(tokenId_, amount_, msg.sender);
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

    /// @inheritdoc IBillboard
    function withdrawTax(uint256 tokenId_) external {
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
        if (amount == 0) revert WithdrawFailed();

        // transfer bid price and tax back to the bidder
        registry.transferAmount(msg.sender, amount);

        // set bid.isWithdrawn to true
        registry.setBid(tokenId_, auctionId_, msg.sender, false, true);
    }
}
