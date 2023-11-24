//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBillboardRegistry is IERC721 {
    //////////////////////////////
    /// Event
    //////////////////////////////

    /**
     * @notice Board name is updated.
     *
     * @param tokenId Token ID of the board.
     * @param name New name of the board.
     */
    event BoardNameUpdated(uint256 indexed tokenId, string name);

    /**
     * @notice Board description is updated.
     *
     * @param tokenId Token ID of the board.
     * @param description New description of the board.
     */
    event BoardDescriptionUpdated(uint256 indexed tokenId, string description);

    /**
     * @notice Board location is updated.
     *
     * @param tokenId Token ID of the board.
     * @param location New location of the board.
     */
    event BoardLocationUpdated(uint256 indexed tokenId, string location);

    /**
     * @notice Board content URI is updated.
     *
     * @param tokenId Token ID of the board.
     * @param contentURI New content URI of the board.
     */
    event BoardContentURIUpdated(uint256 indexed tokenId, string contentURI);

    /**
     * @notice Board redirect URI is updated.
     *
     * @param tokenId Token ID of the board.
     * @param redirectURI New redirect URI of the board.
     */
    event BoardRedirectURIUpdated(uint256 indexed tokenId, string redirectURI);

    /**
     * @notice Global tax rate is updated.
     *
     * @param taxRate New tax rate.
     */
    event TaxRateUpdated(uint256 taxRate);

    /**
     * @notice Auction is created.
     *
     * @param tokenId Token ID of the board.
     * @param auctionId Auction ID of the auction.
     * @param startAt Start time of the auction.
     * @param endAt End time of the auction.
     */
    event AuctionCreated(uint256 indexed tokenId, uint256 indexed auctionId, uint64 startAt, uint64 endAt);

    /**
     * @notice Auction is cleared.
     *
     * @param tokenId Token ID of the board.
     * @param auctionId Auction ID of the auction.
     * @param highestBidder Highest bidder of the auction.
     * @param leaseStartAt Start time of the lease.
     * @param leaseEndAt End time of the lease.
     */
    event AuctionCleared(
        uint256 indexed tokenId,
        uint256 indexed auctionId,
        address indexed highestBidder,
        uint64 leaseStartAt,
        uint64 leaseEndAt
    );

    /**
     * @notice Bid is created.
     *
     * @param tokenId Token ID of the board.
     * @param auctionId Auction ID of the auction.
     * @param bidder Bidder of the auction.
     * @param price Price of the bid.
     * @param tax Tax of the bid.
     */
    event BidCreated(
        uint256 indexed tokenId,
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 price,
        uint256 tax
    );

    /**
     * @notice Bid is won.
     *
     * @param tokenId Token ID of the board.
     * @param auctionId Auction ID of the auction.
     * @param bidder Bidder of the auction.
     */
    event BidWon(uint256 indexed tokenId, uint256 indexed auctionId, address indexed bidder);

    /**
     * @notice Bid is withdrawn.
     *
     * @param tokenId Token ID of the board.
     * @param auctionId Auction ID of the auction.
     * @param bidder Bidder of the auction.
     * @param price Price of the bid.
     * @param tax Tax of the bid.
     */
    event BidWithdrawn(
        uint256 indexed tokenId,
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 price,
        uint256 tax
    );

    /**
     * @notice Tax is withdrawn.
     *
     * @param owner Owner of the treasury.
     * @param amount Amount of the tax.
     */
    event TaxWithdrawn(address indexed owner, uint256 amount);

    //////////////////////////////
    /// Struct
    //////////////////////////////

    struct Board {
        address creator;
        string name;
        string description;
        string location;
        string contentURI;
        string redirectURI;
    }

    struct Auction {
        uint64 startAt; // timestamp
        uint64 endAt; // timestamp
        uint64 leaseStartAt; // timestamp
        uint64 leaseEndAt; // timestamp
        address highestBidder;
    }

    struct Bid {
        uint256 price;
        uint256 tax;
        uint256 placedAt; // timestamp
        bool isWon;
        bool isWithdrawn;
    }

    struct TaxTreasury {
        uint256 accumulated;
        uint256 withdrawn;
    }

    /**
     * @notice Set the new operator.
     *
     * @param operator_ Address of the new operator.
     */
    function setOperator(address operator_) external;

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
     * @notice Transfer a board (NFT) by the operator.
     *
     * @param from_ Address of the board sender.
     * @param to_ Address of the board receiver.
     * @param tokenId_ Token ID of the board.
     */
    function safeTransferByOperator(address from_, address to_, uint256 tokenId_) external;

    /**
     * @notice Get a board
     *
     * @param tokenId_ Token ID of a board.
     */
    function getBoard(uint256 tokenId_) external view returns (Board memory board);

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
     * @notice Get an auction
     *
     * @param tokenId_ Token ID of a board.
     * @param auctionId_ Token ID of a board.
     */
    function getAuction(uint256 tokenId_, uint256 auctionId_) external view returns (Auction memory auction);

    /**
     * @notice Create new auction
     *
     * @param tokenId_ Token ID of a board.
     * @param startAt_ Start time of an auction.
     * @param endAt_ End time of an auction.
     */
    function newAuction(uint256 tokenId_, uint64 startAt_, uint64 endAt_) external returns (uint256 auctionId);

    /**
     * @notice Set the data of an auction
     *
     * @param tokenId_ Token ID of a board.
     * @param auctionId_ Token ID of a board.
     * @param leaseStartAt_ Start time of an board lease.
     * @param leaseEndAt_ End time of an board lease.
     */
    function setAuctionLease(uint256 tokenId_, uint256 auctionId_, uint64 leaseStartAt_, uint64 leaseEndAt_) external;

    /**
     * @notice Get bid count of an auction
     *
     * @param tokenId_ Token ID of a board.
     * @param auctionId_ Auction ID of an auction.
     */
    function getBidCount(uint256 tokenId_, uint256 auctionId_) external view returns (uint256 count);

    /**
     * @notice Get a bid of an auction
     *
     * @param tokenId_ Token ID of a board.
     * @param auctionId_ Auction ID of an auction.
     * @param bidder_ Bidder of an auction.
     */
    function getBid(uint256 tokenId_, uint256 auctionId_, address bidder_) external view returns (Bid memory bid);

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
     * @notice Set isWon of a bid
     *
     * @param tokenId_ Token ID of a board.
     * @param auctionId_ Auction ID of an auction.
     * @param bidder_ Bidder of an auction.
     * @param isWon_ Whether a bid is won.
     */
    function setBidWon(uint256 tokenId_, uint256 auctionId_, address bidder_, bool isWon_) external;

    /**
     * @notice Set isWithdrawn of a bid
     *
     * @param tokenId_ Token ID of a board.
     * @param auctionId_ Auction ID of an auction.
     * @param bidder_ Bidder of an auction.
     * @param isWithdrawn_ Whether a bid is won.
     */
    function setBidWithdrawn(uint256 tokenId_, uint256 auctionId_, address bidder_, bool isWithdrawn_) external;

    /**
     * @notice Transfer amount to a receiver.
     *
     * @param to_ Address of a receiver.
     * @param amount_ Amount.
     */
    function transferAmount(address to_, uint256 amount_) external;

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

    //////////////////////////////
    /// Event emission
    //////////////////////////////

    /**
     * @notice Emit `AuctionCleared` event.
     *
     * @param tokenId_ Token ID of a board.
     * @param auctionId_ Auction ID of an auction.
     * @param highestBidder_ Highest bidder of an auction.
     * @param leaseStartAt_ Start time of an board lease.
     * @param leaseEndAt_ End time of an board lease.
     */
    function emitAuctionCleared(
        uint256 tokenId_,
        uint256 auctionId_,
        address highestBidder_,
        uint64 leaseStartAt_,
        uint64 leaseEndAt_
    ) external;

    /**
     * @notice Emit `BidWithdrawn` event.
     *
     * @param tokenId_ Token ID of a board.
     * @param auctionId_ Auction ID of an auction.
     * @param bidder_ Bidder of an auction.
     * @param price_ Price of a bid.
     * @param tax_ Tax of a bid.
     */
    function emitBidWithdrawn(
        uint256 tokenId_,
        uint256 auctionId_,
        address bidder_,
        uint256 price_,
        uint256 tax_
    ) external;

    /**
     * @notice Emit `TaxWithdrawn` event.
     *
     * @param owner_ Address of a treasury owner.
     * @param amount_ Amount.
     */
    function emitTaxWithdrawn(address owner_, uint256 amount_) external;
}
