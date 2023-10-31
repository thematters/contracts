//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "./IBillboardAuction.sol";

contract BillboardAuction is IBillboardAuction {
    bool public isOpened = false;

    address public admin;

    address public operator;

    uint256 public taxRate;

    mapping(uint256 => Auction) public auctions;

    mapping(uint256 => address[]) public bidders;

    mapping(uint256 => mapping(address => Bid)) public currentBids;

    mapping(uint256 => Bid) public currentHighestBids;

    mapping(uint256 => uint256) public lockedTaxations;

    mapping(uint256 => Treasury) public treasuries;

    constructor(
        address admin_,
        address operator_,
        uint256 taxRate_
    ) {
        admin = admin_;
        operator = operator_;
        taxRate = taxRate_;
    }

    //////////////////////////////
    /// Modifier
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
            revert Unauthorzied("admin");
        }
        _;
    }

    modifier isFromOperator() {
        if (operator == address(0)) {
            revert OperatorNotFound();
        }
        if (msg.sender == address(0)) {
            revert InvalidAddress();
        }
        if (msg.sender != operator) {
            revert Unauthorzied("operator");
        }
        _;
    }

    /// @inheritdoc IBillboardAuction
    function setIsOpened(bool value_, address sender_) external isAdmin(sender_) isFromOperator {
        isOpened = value_;
    }

    /// @inheritdoc IBillboardAuction
    function setTaxRate(uint256 taxRate_, address sender_) external isAdmin(sender_) isFromOperator {
        taxRate = taxRate_;
    }

    /// @inheritdoc IBillboardAuction
    function initTreasury(uint256 tokenId_) external isFromOperator {
        // TODO
    }

    /// @inheritdoc IBillboardAuction
    function placeBid(
        uint256 tokenId_,
        uint256 amount_,
        address sender_
    ) external isFromOperator isAdmin(sender_) {
        // TODO
    }

    /// @inheritdoc IBillboardAuction
    function getBid(uint256 tokenId_, address bidder_) external view isValidAddress(bidder_) returns (Bid memory bid) {
        return currentBids[tokenId_][bidder_];
    }

    /// @inheritdoc IBillboardAuction
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
            Bid[] memory bids
        )
    {
        // TODO
    }

    /// @inheritdoc IBillboardAuction
    function initAuction(uint256 tokenId_) external isFromOperator {
        // TODO
    }

    /// @inheritdoc IBillboardAuction
    function getAuction(uint256 tokenId_) external view returns (Auction memory auction) {
        return auctions[tokenId_];
    }

    /// @inheritdoc IBillboardAuction
    function clearAuction(uint256 tokenId_) external {
        // TODO
    }

    /**
     * @notice Refund to bidders who are not winning auction of a board.
     *
     * @param tokenId_ Token ID of a board.
     */
    function _refund(uint256 tokenId_) internal {
        // TODO
    }

    /// @inheritdoc IBillboardAuction
    function withdraw(uint256 tokenId_, address sender_) external {
        // TODO
    }
}
