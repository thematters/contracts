//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "./BillboardAuction.sol";
import "./BillboardRegistry.sol";
import "./IBillboard.sol";
import "./IBillboardAuction.sol";
import "./IBillboardRegistry.sol";

contract Billboard is IBillboard {
    address public admin;

    BillboardAuction public auction;

    BillboardRegistry public registry;

    constructor() {
        admin = msg.sender;
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

    modifier isAdmin(address value_) {
        if (admin == address(0)) {
            revert AdminNotFound();
        }
        if (value_ == address(0)) {
            revert InvalidAddress();
        }
        if (value_ != admin) {
            revert Unauthorized("admin");
        }
        _;
    }

    //////////////////////////////
    /// Upgradability
    //////////////////////////////

    /// @inheritdoc IBillboard
    function upgradeAuction(address contract_) external isValidAddress(contract_) isAdmin(msg.sender) {
        auction = BillboardAuction(contract_);
    }

    /// @inheritdoc IBillboard
    function upgradeRegistry(address contract_) external isValidAddress(contract_) isAdmin(msg.sender) {
        registry = BillboardRegistry(contract_);
    }

    /// @inheritdoc IBillboard
    function setIsOpened(bool value_) external isAdmin(msg.sender) {
        if (address(registry) == address(0)) {
            revert InvalidAddress();
        }
        if (address(auction) == address(0)) {
            revert InvalidAddress();
        }

        registry.setIsOpened(value_, msg.sender);
        auction.setIsOpened(value_, msg.sender);
    }

    //////////////////////////////
    /// Board
    //////////////////////////////

    /// @inheritdoc IBillboard
    function mintBoard(address to_) external isValidAddress(to_) {
        uint256 tokenId = registry.mint(to_, msg.sender);
        auction.initTreasury(tokenId);
    }

    /// @inheritdoc IBillboard
    function getBoard(uint256 tokenId_) external view returns (IBillboardRegistry.Board memory board) {
        return registry.getBoard(tokenId_);
    }

    /// @inheritdoc IBillboard
    function setBoardName(uint256 tokenId_, string memory name_) external {
        registry.setBoardName(tokenId_, name_, msg.sender);
    }

    /// @inheritdoc IBillboard
    function setBoardDescription(uint256 tokenId_, string memory description_) external {
        registry.setBoardDescription(tokenId_, description_, msg.sender);
    }

    /// @inheritdoc IBillboard
    function setBoardLocation(uint256 tokenId_, string memory location_) external {
        registry.setBoardLocation(tokenId_, location_, msg.sender);
    }

    /// @inheritdoc IBillboard
    function setBoardContentURI(uint256 tokenId_, string memory uri_) external {
        registry.setBoardContentURI(tokenId_, uri_, msg.sender);
    }

    /// @inheritdoc IBillboard
    function setBoardRedirectLink(uint256 tokenId_, string memory redirectLink_) external {
        registry.setBoardRedirectLink(tokenId_, redirectLink_, msg.sender);
    }

    //////////////////////////////
    /// Auction
    //////////////////////////////

    /// @inheritdoc IBillboard
    function setTaxRate(uint256 taxRate_) external isAdmin(msg.sender) {
        auction.setTaxRate(taxRate_, msg.sender);
    }

    /// @inheritdoc IBillboard
    function getTaxRate() external view returns (uint256 taxRate) {
        return auction.taxRate();
    }

    /// @inheritdoc IBillboard
    function placeBid(uint256 tokenId_, uint256 amount_) external {
        auction.placeBid(tokenId_, amount_, msg.sender);
    }

    /// @inheritdoc IBillboard
    function getBid(uint256 tokenId_, address bidder_) external view returns (IBillboardAuction.Bid memory bid) {
        return auction.getBid(tokenId_, bidder_);
    }

    /// @inheritdoc IBillboard
    function getBidsByBoard(
        uint256 tokenId_,
        uint256 limit_,
        uint256 offset_
    )
        external
        view
        returns (
            uint256 total,
            uint256 limit,
            uint256 offset,
            IBillboardAuction.Bid[] memory bids
        )
    {
        return auction.getBidsByBoard(tokenId_, limit_, offset_);
    }

    /// @inheritdoc IBillboard
    function clearAuction(uint256 tokenId_) external {
        auction.clearAuction(tokenId_);

        // TODO update board data
    }

    /// @inheritdoc IBillboard
    function withdraw(uint256 tokenId_) external {
        auction.withdraw(tokenId_, msg.sender);
    }
}
