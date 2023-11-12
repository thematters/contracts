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
            revert Unauthorized("board creator");
        }
        _;
    }

    modifier isFromBoardTenant(uint256 tokenId_) {
        if (msg.sender != _ownerOf(tokenId_)) {
            revert Unauthorized("board tenant");
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
        registry.mint(to_, msg.sender);
    }

    /// @inheritdoc IBillboard
    function getBoard(uint256 tokenId_) external view returns (IBillboardRegistry.Board memory board) {
        return registry.boards[tokenId_];
    }

    /// @inheritdoc IBillboard
    function setBoardName(uint256 tokenId_, string memory name_) external isFromBoardCreator {
        registry.setBoardName(tokenId_, name_);
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
    ) external view returns (uint256 total, uint256 limit, uint256 offset, IBillboardRegistry.Bid[] memory bids) {
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
