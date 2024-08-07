//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title The interface for `BillboardRegistry` (registry) contract.
 * @notice Storage contract for `Billboard` (operator) contract.
 * @dev It stores all states, and is controlled by the operator contract.
 */
interface IBillboardRegistry is IERC721 {
    //////////////////////////////
    /// Event
    //////////////////////////////

    /**
     * @notice Operator is updated.
     */
    event OperatorUpdated(address indexed operator);

    /**
     * @notice Board is created.
     *
     * @param tokenId Token ID of the board
     * @param to Address of the board owner.
     * @param taxRate Tax rate of the board.
     * @param epochInterval Epoch interval of the board.
     */
    event BoardCreated(uint256 indexed tokenId, address indexed to, uint256 taxRate, uint256 epochInterval);

    /**
     * @notice Board data is updated.
     *
     * @param tokenId Token ID of the board.
     * @param name Name of the board.
     * @param description Description of the board.
     * @param imageURI Image URI of the board.
     * @param location Location of the board.
     */
    event BoardUpdated(uint256 indexed tokenId, string name, string description, string imageURI, string location);

    /**
     * @notice Auction is cleared.
     *
     * @param tokenId Token ID of the board.
     * @param epoch Epoch of the auction.
     * @param highestBidder Highest bidder of the auction.
     */
    event AuctionCleared(uint256 indexed tokenId, uint256 indexed epoch, address indexed highestBidder);

    /**
     * @notice Bid is created or updated.
     *
     * @param tokenId Token ID of the board.
     * @param epoch Epoch of the auction.
     * @param bidder Bidder of the auction.
     * @param price Price of the bid.
     * @param tax Tax of the bid.
     * @param contentURI Content URI of the bid.
     * @param redirectURI Redirect URI of the bid.
     */
    event BidUpdated(
        uint256 indexed tokenId,
        uint256 indexed epoch,
        address indexed bidder,
        uint256 price,
        uint256 tax,
        string contentURI,
        string redirectURI
    );

    /**
     * @notice Bid is won.
     *
     * @param tokenId Token ID of the board.
     * @param epoch Epoch of the auction.
     * @param bidder Bidder of the auction.
     */
    event BidWon(uint256 indexed tokenId, uint256 indexed epoch, address indexed bidder);

    /**
     * @notice Bid is withdrawn.
     *
     * @param tokenId Token ID of the board.
     * @param epoch Epoch of the auction.
     * @param bidder Bidder of the auction.
     */
    event BidWithdrawn(uint256 indexed tokenId, uint256 indexed epoch, address indexed bidder);

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
        // immutable data
        address creator;
        uint256 taxRate;
        uint256 epochInterval; // in blocks
        uint256 startedAt; // gensis epoch, block number
        // mutable data
        string name;
        string description;
        string imageURI;
        string location;
    }

    struct Bid {
        uint256 price;
        uint256 tax;
        string contentURI;
        string redirectURI;
        uint256 placedAt; // block number
        uint256 updatedAt; // block number
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
     * @notice Get a board
     *
     * @param tokenId_ Token ID of a board.
     */
    function getBoard(uint256 tokenId_) external view returns (Board memory board);

    /**
     * @notice Mint a new board (NFT).
     *
     * @param to_ Address of the board owner.
     * @param taxRate_ Tax rate of the new board.
     * @param epochInterval_ Epoch interval of the new board.
     * @param startedAt_ Block number when the board starts the first epoch.
     *
     * @return tokenId Token ID of the new board.
     */
    function newBoard(
        address to_,
        uint256 taxRate_,
        uint256 epochInterval_,
        uint256 startedAt_
    ) external returns (uint256 tokenId);

    /**
     * @notice Set metadata of a board.
     *
     * @param tokenId_ Token ID of a board.
     * @param name_ Board name.
     * @param description_ Board description.
     * @param imageURI_ Image URI of a board.
     * @param location_ Location of a board.
     */
    function setBoard(
        uint256 tokenId_,
        string calldata name_,
        string calldata description_,
        string calldata imageURI_,
        string calldata location_
    ) external;

    //////////////////////////////
    /// Auction & Bid
    //////////////////////////////

    /**
     * @notice Get a bid of an auction
     *
     * @param tokenId_ Token ID of a board.
     * @param epoch_ Epoch of an auction.
     * @param bidder_ Bidder of an auction.
     */
    function getBid(uint256 tokenId_, uint256 epoch_, address bidder_) external view returns (Bid memory bid);

    /**
     * @notice Get bid count of an auction
     *
     * @param tokenId_ Token ID of a board.
     * @param epoch_ Epoch.
     *
     * @return count Count of bids.
     */
    function getBidCount(uint256 tokenId_, uint256 epoch_) external view returns (uint256 count);

    /**
     * @notice Get the count of bidder bids
     *
     * @param tokenId_ Token ID of a board.
     * @param bidder_ Bidder of an auction.
     *
     * @return count Count of bids.
     */
    function getBidderBidCount(uint256 tokenId_, address bidder_) external view returns (uint256 count);

    /**
     * @notice Create a bid
     *
     * @param tokenId_ Token ID of a board.
     * @param epoch_ Epoch of an auction.
     * @param bidder_ Bidder of an auction.
     * @param price_ Price of a bid.
     * @param tax_ Tax of a bid.
     * @param contentURI_ Content URI of a bid.
     * @param redirectURI_ Redirect URI of a bid.
     */
    function newBid(
        uint256 tokenId_,
        uint256 epoch_,
        address bidder_,
        uint256 price_,
        uint256 tax_,
        string calldata contentURI_,
        string calldata redirectURI_
    ) external;

    /**
     * @notice Update a bid
     *
     * @param tokenId_ Token ID of a board.
     * @param epoch_ Epoch of an auction.
     * @param bidder_ Bidder of an auction.
     * @param price_ Price of a bid.
     * @param tax_ Tax of a bid.
     * @param contentURI_ Content URI of a bid.
     * @param redirectURI_ Redirect URI of a bid.
     * @param hasURIs_ Whether `contentURI_` or `redirectURI_` is provided.
     */
    function setBid(
        uint256 tokenId_,
        uint256 epoch_,
        address bidder_,
        uint256 price_,
        uint256 tax_,
        string calldata contentURI_,
        string calldata redirectURI_,
        bool hasURIs_
    ) external;

    /**
     * @notice Set the content URI and redirect URI of a board.
     *
     * @param tokenId_ Token ID of a board.
     * @param epoch_ Epoch.
     * @param bidder_ Bidder of an auction.
     * @param contentURI_ Content URI of a board.
     * @param redirectURI_ Redirect URI of a board.
     */
    function setBidURIs(
        uint256 tokenId_,
        uint256 epoch_,
        address bidder_,
        string calldata contentURI_,
        string calldata redirectURI_
    ) external;

    /**
     * @notice Set isWon of a bid
     *
     * @param tokenId_ Token ID of a board.
     * @param epoch_ Epoch of an auction.
     * @param bidder_ Bidder of an auction.
     * @param isWon_ Whether a bid is won.
     */
    function setBidWon(uint256 tokenId_, uint256 epoch_, address bidder_, bool isWon_) external;

    /**
     * @notice Set isWithdrawn of a bid
     *
     * @param tokenId_ Token ID of a board.
     * @param epoch_ Epoch of an auction.
     * @param bidder_ Bidder of an auction.
     * @param isWithdrawn_ Whether a bid is won.
     */
    function setBidWithdrawn(uint256 tokenId_, uint256 epoch_, address bidder_, bool isWithdrawn_) external;

    //////////////////////////////
    /// Tax & Withdraw
    //////////////////////////////

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
     * @param epoch_ Epoch of an auction.
     * @param highestBidder_ Highest bidder of an auction.
     */
    function emitAuctionCleared(uint256 tokenId_, uint256 epoch_, address highestBidder_) external;

    /**
     * @notice Emit `TaxWithdrawn` event.
     *
     * @param owner_ Address of a treasury owner.
     * @param amount_ Amount.
     */
    function emitTaxWithdrawn(address owner_, uint256 amount_) external;

    //////////////////////////////
    /// ERC20 & ERC721 related
    //////////////////////////////

    /**
     * @notice Transfer a board (NFT).
     *
     * @param from_ Address of the board sender.
     * @param to_ Address of the board receiver.
     * @param tokenId_ Token ID of the board.
     */
    function safeTransferByOperator(address from_, address to_, uint256 tokenId_) external;

    /**
     * @notice Transfer amount of token to a receiver.
     *
     * @param to_ Address of a receiver.
     * @param amount_ Amount.
     */
    function transferCurrencyByOperator(address to_, uint256 amount_) external;

    /**
     * @dev If an ERC721 token has been minted.
     */
    function exists(uint256 tokenId_) external view returns (bool);
}
