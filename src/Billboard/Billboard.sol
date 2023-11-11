//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "./BillboardRegistry.sol";
import "./IBillboard.sol";
import "./IBillboardRegistry.sol";

contract Billboard is IBillboard {
    address public admin;

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
        if (value_ != admin) {
            revert Unauthorized("admin");
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

    /// @inheritdoc IBillboard
    function setIsOpened(bool value_) external isAdmin(msg.sender) {
        registry.setIsOpened(value_, msg.sender);
    }

    /// @inheritdoc IBillboard
    function addToWhitelist(address value_) external isAdmin(msg.sender) {
        registry.addToWhitelist(value_, msg.sender);
    }

    /// @inheritdoc IBillboard
    function removeFromWhitelist(address value_) external isAdmin(msg.sender) {
        registry.removeFromWhitelist(value_, msg.sender);
    }

    //////////////////////////////
    /// Board
    //////////////////////////////

    /// @inheritdoc IBillboard
    function mintBoard(address to_) external isValidAddress(to_) {
        uint256 tokenId = registry.mint(to_, msg.sender);
        registry.initTreasury(tokenId);
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
    function setBoardRedirectURI(uint256 tokenId_, string memory redirectURI_) external {
        registry.setBoardRedirectURI(tokenId_, redirectURI_, msg.sender);
    }

    //////////////////////////////
    /// Auction
    //////////////////////////////

    /// @inheritdoc IBillboard
    function setTaxRate(uint256 taxRate_) external isAdmin(msg.sender) {
        registry.setTaxRate(taxRate_, msg.sender);
    }

    /// @inheritdoc IBillboard
    function getTaxRate() external view returns (uint256 taxRate) {
        return registry.taxRate();
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
            IBillboardRegistry.Bid[] memory bids
        )
    {
        return registry.getBidsByBoard(tokenId_, limit_, offset_);
    }

    /// @inheritdoc IBillboard
    function clearAuction(uint256 tokenId_) external {
        registry.clearAuction(tokenId_);

        // TODO update board data
    }

    /// @inheritdoc IBillboard
    function withdraw(uint256 tokenId_) external {
        registry.withdraw(tokenId_, msg.sender);
    }
}
