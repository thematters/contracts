//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

interface IBillboardAuction {
    //////////////////////////////
    /// Error
    //////////////////////////////

    error AdminNotFound();

    error AuctionNotFound();

    error InvalidAddress();

    error OperatorNotFound();

    error Unauthorized(string type_);

    //////////////////////////////
    /// Struct
    //////////////////////////////

    struct Auction {
        uint256 startBlock;
        uint256 endBlock;
    }

    struct Bid {
        uint256 atBlock;
        uint256 amount;
    }

    struct Treasury {
        address owner;
        uint256 amount;
    }

    /**
     * @notice Toggle for operation access.
     *
     * @param value_ Value of access state.
     * @param sender_ Address of user who wants to set.
     */
    function setIsOpened(bool value_, address sender_) external;

    /**
     * @notice Add address to white list.
     *
     * @param value_ Address of user will be added into white list.
     * @param sender_ Address of user who wants to update white list.
     */
    function addToWhitelist(address value_, address sender_) external;

    /**
     * @notice Remove address from white list.
     *
     * @param value_ Address of user will be removed from white list.
     * @param sender_ Address of user who wants to update white list.
     */
    function removeFromWhitelist(address value_, address sender_) external;

    /**
     * @notice Set the global tax rate.
     *
     * @param taxRate_ Tax rate.
     * @param sender_ Address of user who wants to set.
     */
    function setTaxRate(uint256 taxRate_, address sender_) external;

    /**
     * @notice Initialize a treasury when a new board minted.
     *
     * @param tokenId_ Token ID of a board.
     */
    function initTreasury(uint256 tokenId_) external;

    /**
     * @notice Place bid for a board.
     *
     * @param tokenId_ Token ID of a board.
     * @param amount_ Amount of a bid.
     * @param sender_ Address of user who wants to bid.
     */
    function placeBid(
        uint256 tokenId_,
        uint256 amount_,
        address sender_
    ) external;

    /**
     * @notice Place bid for a board.
     *
     * @param tokenId_ Token ID of a board.
     * @param bidder_ Address of a bidder.
     *
     * @return bid Bid of a board.
     */
    function getBid(uint256 tokenId_, address bidder_) external view returns (Bid memory bid);

    /**
     * @notice Get bids of a board.
     *
     * @param tokenId_ Token ID of a board.
     * @param limit_ Limit of returned bids.
     * @param offset_ Offset of returned bids.
     *
     * @return total Total number of bids.
     * @return limit Limit of returned bids.
     * @return offset Offset of returned bids.
     * @return bids Bids of a board.
     */
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
        );

    /**
     * @notice Initialize a new auction of a board.
     *
     * @param tokenId_ Token ID of a board.
     */
    function initAuction(uint256 tokenId_) external;

    /**
     * @notice Get the current auction of a board if it exists.
     *
     * @param tokenId_ Token ID of a board.
     */
    function getAuction(uint256 tokenId_) external view returns (Auction memory auction);

    /**
     * @notice Clear a board auction.
     *
     * @param tokenId_ Token ID of a board.
     */
    function clearAuction(uint256 tokenId_) external;

    /**
     * @notice Withdraw accumulated taxation of a board.
     *
     * @param tokenId_ Token ID of a board.
     * @param sender_ Address of user wants to withdraw.
     */
    function withdraw(uint256 tokenId_, address sender_) external;
}
