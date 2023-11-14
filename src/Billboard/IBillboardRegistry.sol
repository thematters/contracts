//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBillboardRegistry is IERC721 {
    //////////////////////////////
    /// Error
    //////////////////////////////

    error InvalidAddress();

    error Unauthorized(string type_);

    error ZeroAmount();

    error TransferFailed();

    //////////////////////////////
    /// Event
    //////////////////////////////

    // TODO
    // mint & transfer (no need, inherted from ERC721)
    // set board (name, uris, etc.)
    // set tax rate
    // new auction
    // clear auction
    // new bid
    // withdraw bid
    // withdraw tax

    //////////////////////////////
    /// Struct
    //////////////////////////////

    struct Board {
        address creator;
        uint256 auctionId; // last lease auction ID
        string name;
        string description;
        string location;
        string contentURI;
        string redirectURI;
    }

    struct Auction {
        uint256 tokenId;
        uint256 startAt; // timestamp
        uint256 endAt; // timestamp
        uint256 leaseStartAt; // timestamp
        uint256 leaseEndAt; // timestamp
        address highestBidder;
    }

    struct Bid {
        address bidder;
        uint256 price;
        uint256 tax;
        uint256 auctionId;
        uint256 placedAt; // timestamp
        bool isWon;
        bool isWithdrawn;
    }

    struct TaxTreasury {
        address owner;
        uint256 accumulated;
        uint256 withdrawn;
    }

    //////////////////////////////
    /// Board
    //////////////////////////////

    /**
     * @notice Mint a new board (NFT).
     *
     * @param to_ Address of the new board receiver.
     *
     * @return tokenId Token ID of the new board.
     */
    function mintBoard(address to_) external returns (uint256 tokenId);

    /**
     * @notice Set the auctionId of a board.
     *
     * @param tokenId_ Token ID of a board.
     * @param auctionId_ Auction ID of an auction.
     */
    function setBoardAuctionId(uint256 tokenId_, uint256 auctionId_) external;

    /**
     * @notice Set the name of a board by board creator.
     *
     * @param tokenId_ Token ID of a board.
     * @param name_ Board name.
     */
    function setBoardName(uint256 tokenId_, string calldata name_) external;

    /**
     * @notice Set the name of a board by board creator.
     *
     * @param tokenId_ Token ID of a board.
     * @param description_ Board description.
     */
    function setBoardDescription(uint256 tokenId_, string calldata description_) external;

    /**
     * @notice Set the location of a board by board creator.
     *
     * @param tokenId_ Token ID of a board.
     * @param location_ Digital address where a board located.
     */
    function setBoardLocation(uint256 tokenId_, string calldata location_) external;

    /**
     * @notice Set the content URI and redirect URI of a board by the tenant
     *
     * @param tokenId_ Token ID of a board.
     * @param contentURI_ Content URI of a board.
     */
    function setBoardContentURI(uint256 tokenId_, string calldata contentURI_) external;

    /**
     * @notice Set the redirect URI and redirect URI of a board by the tenant
     *
     * @param tokenId_ Token ID of a board.
     * @param redirectURI_ Redirect URI when users clicking.
     */
    function setBoardRedirectURI(uint256 tokenId_, string calldata redirectURI_) external;

    //////////////////////////////
    /// Auction
    //////////////////////////////

    /**
     * @notice Create new auction
     *
     * @param tokenId_ Token ID of a board.
     * @param startAt_ Start time of an auction.
     * @param endAt_ End time of an auction.
     */
    function newAuction(uint256 tokenId_, uint256 startAt_, uint256 endAt_) external returns (uint256 auctionId);

    /**
     * @notice Set the data of an auction
     *
     * @param tokenId_ Token ID of a board.
     * @param auctionId_ Token ID of a board.
     * @param leaseStartAt_ Start time of an board lease.
     * @param leaseEndAt_ End time of an board lease.
     */
    function setAuctionLease(uint256 tokenId_, uint256 auctionId_, uint256 leaseStartAt_, uint256 leaseEndAt_) external;

    /**
     * @notice Create new bid and add it to auction
     *
     * 1. Create new bid: `new Bid()`
     * 2. Add bid to auction:
     *     - `auction.bids[bidder] = bid`
     *     - `auction.bidders.push(bidder)`
     *     - if any `auction.highestBidder = bidder`
     *
     * @param tokenId_ Token ID of a board.
     * @param auctionId_ Auction ID of an auction.
     * @param bidder_ Bidder of an auction.
     * @param price_ Price of a bid.
     * @param tax_ Tax of a bid.
     */
    function newBid(uint256 tokenId_, uint256 auctionId_, address bidder_, uint256 price_, uint256 tax_) external;

    /**
     * @notice Set the data of a bid
     *
     * @param tokenId_ Token ID of a board.
     * @param auctionId_ Auction ID of an auction.
     * @param bidder_ Bidder of an auction.
     * @param isWon_ Whether a bid is won.
     * @param isWithdrawn_ Whether a bid is won.
     */
    function setBid(uint256 tokenId_, uint256 auctionId_, address bidder_, bool isWon_, bool isWithdrawn_) external;

    /**
     * @notice Transfer amount of bid price to current board owner (last tenant)
     *
     * @param tokenId_ Token ID of a board.
     * @param auctionId_ Auction ID of an auction.
     * @param bidder_ Bidder of the highest bid.
     * @param to_ Address of a receiver.
     */
    function transferBidAmount(uint256 tokenId_, uint256 auctionId_, address bidder_, address to_) external;

    //////////////////////////////
    /// Tax & Withdraw
    //////////////////////////////

    /**
     * @notice Set the global tax rate.
     *
     * @param taxRate_ Tax rate.
     */
    function setTaxRate(uint256 taxRate_) external;

    /**
     * @notice Set the tax treasury.
     *
     * @param owner_ Address of a treasury owner.
     * @param accumulated_ Accumulated tax.
     * @param withdrawn_ Withdrawn tax.
     */
    function setTaxTreasury(address owner_, uint256 accumulated_, uint256 withdrawn_) external;
}
