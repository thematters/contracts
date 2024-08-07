//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "./IBillboardRegistry.sol";

/**
 * @title The interface for `Billboard` contract
 * @notice The on-chain billboard system transforms platform attention into NFT billboards based on Harberger tax auctions. Empowering creators with a fair share of tax revenue through quadratic voting.
 *
 * ## Billboard
 * - User can mint a billboard: `mintBoard`.
 * - Creator, who mints the billboard, can set the metadata: `setBoard`.
 * - Tenant, who wins the auction, can set the AD data: `setBidURIs`.
 *
 * ## Auction & Bid
 * - Creator can set a epoch interval when `mintBoard`.
 * - User needs to call `approve` on currency (e.g. USDT) contract before starting.
 * - User can place a bid on a billboard: `placeBid`.
 * - User can clear auction on a billboard: `clearAuction`.
 * - User can withdraw a bid: `withdrawBid`.
 *
 * ## Tax
 * - Creator can set a tax rate when `mintBoard`.
 * - Creator can withdraw tax: `withdrawTax`.
 *
 * @dev This contract holds the logic, while read from and write into {BillboardRegistry}, which is the storage contact.
 * @dev This contract use the {BillboardRegistry} contract for storage, and can be updated by transfering ownership to a new implementation contract.
 */
interface IBillboard {
    //////////////////////////////
    /// Upgradability
    //////////////////////////////

    /**
     * @notice Set the address of operator to current registry contract.
     *
     * @param operator_ Address of operator_.
     */
    function setRegistryOperator(address operator_) external;

    //////////////////////////////
    /// Access control
    //////////////////////////////

    /**
     * @notice Add or remove whitelist address.
     *
     * @param tokenId_ Token ID.
     * @param account_ Address of user will be added into whitelist.
     * @param whitelisted Whitelisted or not.
     */
    function setWhitelist(uint256 tokenId_, address account_, bool whitelisted) external;

    /**
     * @notice Open or close a board.
     *
     * @param tokenId_ Token ID.
     * @param closed Closed or not.
     */
    function setClosed(uint256 tokenId_, bool closed) external;

    //////////////////////////////
    /// Board
    //////////////////////////////

    /**
     * @notice Mint a new board (NFT).
     *
     * @param taxRate_ Tax rate per epoch. (e.g. 1024 for 10.24% per epoch)
     * @param epochInterval_ Epoch interval in blocks (e.g. 100 for 100 blocks).
     *
     * @return tokenId Token ID of the new board.
     */
    function mintBoard(uint256 taxRate_, uint256 epochInterval_) external returns (uint256 tokenId);

    /**
     * @notice Mint a new board (NFT).
     *
     * @param taxRate_ Tax rate per epoch. (e.g. 1024 for 10.24% per epoch)
     * @param epochInterval_ Epoch interval in blocks (e.g. 100 for 100 blocks).
     * @param startedAt_ Block number when the board starts the first epoch.
     *
     * @return tokenId Token ID of the new board.
     */
    function mintBoard(uint256 taxRate_, uint256 epochInterval_, uint256 startedAt_) external returns (uint256 tokenId);

    /**
     * @notice Get metadata of a board .
     *
     * @param tokenId_ Token ID of a board.
     *
     * @return board Board metadata.
     */
    function getBoard(uint256 tokenId_) external view returns (IBillboardRegistry.Board memory board);

    /**
     * @notice Set metadata of a board by creator.
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
     * @notice Clear an auction by a given epoch.
     *
     * @param tokenId_ Token ID.
     * @param epoch_ Epoch.
     *
     * @return highestBidder Address of the highest bidder.
     * @return price Price of the highest bid.
     * @return tax Tax of the highest bid.
     */
    function clearAuction(
        uint256 tokenId_,
        uint256 epoch_
    ) external returns (address highestBidder, uint256 price, uint256 tax);

    /**
     * @notice Clear the next auction of mutiple boards.
     *
     * @param tokenIds_ Token IDs of boards.
     * @param epochs_ Epochs of auctions.
     *
     * @return highestBidders Addresses of the highest bidders.
     * @return prices Prices of the highest bids.
     * @return taxes Taxes of the highest bids.
     */
    function clearAuctions(
        uint256[] calldata tokenIds_,
        uint256[] calldata epochs_
    ) external returns (address[] calldata highestBidders, uint256[] calldata prices, uint256[] calldata taxes);

    /**
     * @notice Place bid on a board auction.
     *
     * @param tokenId_ Token ID.
     * @param epoch_ Epoch.
     * @param price_ Amount of a bid.
     */
    function placeBid(uint256 tokenId_, uint256 epoch_, uint256 price_) external payable;

    /**
     * @notice Place bid on a board auction.
     *
     * @param tokenId_ Token ID.
     * @param epoch_ Epoch.
     * @param price_ Amount of a bid.
     * @param contentURI_ Content URI of a bid.
     * @param redirectURI_ Redirect URI of a bid.
     */
    function placeBid(
        uint256 tokenId_,
        uint256 epoch_,
        uint256 price_,
        string calldata contentURI_,
        string calldata redirectURI_
    ) external payable;

    /**
     * @notice Set the content URI and redirect URI of a board.
     *
     * @param tokenId_ Token ID of a board.
     * @param epoch_ Epoch.
     * @param contentURI_ Content URI of a board.
     * @param redirectURI_ Redirect URI of a board.
     */
    function setBidURIs(
        uint256 tokenId_,
        uint256 epoch_,
        string calldata contentURI_,
        string calldata redirectURI_
    ) external;

    /**
     * @notice Get bid of a board auction.
     *
     * @param tokenId_ Token ID of a board.
     * @param epoch_ Epoch of an auction.
     * @param bidder_ Address of a bidder.
     *
     * @return bid Bid of a board.
     */
    function getBid(
        uint256 tokenId_,
        uint256 epoch_,
        address bidder_
    ) external view returns (IBillboardRegistry.Bid memory bid);

    /**
     * @notice Get bids of a board auction.
     *
     * @param tokenId_ Token ID.
     * @param epoch_ Epoch.
     * @param limit_ Limit of returned bids.
     * @param offset_ Offset of returned bids.
     *
     * @return total Total number of bids.
     * @return limit Limit of returned bids.
     * @return offset Offset of returned bids.
     * @return bids Bids.
     */
    function getBids(
        uint256 tokenId_,
        uint256 epoch_,
        uint256 limit_,
        uint256 offset_
    ) external view returns (uint256 total, uint256 limit, uint256 offset, IBillboardRegistry.Bid[] memory bids);

    /**
     * @notice Get all bids of bidder by token ID.
     *
     * @param tokenId_ Token ID.
     * @param bidder_ Address of bidder.
     * @param limit_ Limit of returned bids.
     * @param offset_ Offset of returned bids.
     *
     * @return total Total number of bids.
     * @return limit Limit of returned bids.
     * @return offset Offset of returned bids.
     * @return bids Bids.
     */
    function getBidderBids(
        uint256 tokenId_,
        address bidder_,
        uint256 limit_,
        uint256 offset_
    ) external view returns (uint256 total, uint256 limit, uint256 offset, IBillboardRegistry.Bid[] memory bids);

    /**
     * @notice Withdraw bid that were not won by auction id;
     *
     * @param tokenId_ Token ID.
     * @param epoch_ Epoch.
     * @param bidder_ Address of bidder.
     */
    function withdrawBid(uint256 tokenId_, uint256 epoch_, address bidder_) external;

    /**
     * @notice Calculate epoch from block number.
     *
     * @param startedAt_ Started at block number.
     * @param block_ Block number.
     * @param epochInterval_ Epoch interval.
     *
     * @return epoch Epoch.
     */
    function getEpochFromBlock(
        uint256 startedAt_,
        uint256 block_,
        uint256 epochInterval_
    ) external pure returns (uint256 epoch);

    /**
     * @notice Calculate block number from epoch.
     *
     * @param startedAt_ Started at block number.
     * @param epoch_ Epoch.
     * @param epochInterval_ Epoch interval.
     *
     * @return blockNumber Block number.
     */
    function getBlockFromEpoch(
        uint256 startedAt_,
        uint256 epoch_,
        uint256 epochInterval_
    ) external pure returns (uint256 blockNumber);

    //////////////////////////////
    /// Tax & Withdraw
    //////////////////////////////

    /**
     * @notice Get the global tax rate.
     *
     * @param tokenId_ Token ID.
     *
     * @return taxRate Tax rate.
     */
    function getTaxRate(uint256 tokenId_) external view returns (uint256 taxRate);

    /**
     * @notice Calculate tax of a bid.
     *
     * @param tokenId_ Token ID.
     * @param amount_ Amount of a bid.
     *
     * @return tax Tax of a bid.
     */
    function calculateTax(uint256 tokenId_, uint256 amount_) external returns (uint256 tax);

    /**
     * @notice Withdraw accumulated taxation.
     *
     * @param creator_ Address of board creator.
     *
     */
    function withdrawTax(address creator_) external returns (uint256 tax);

    //////////////////////////////
    /// ERC721 related
    //////////////////////////////

    /**
     * @notice Get token URI by registry contract.
     *
     * @dev Access: only registry.
     *
     * @param tokenId_ Token id to be transferred.
     * @return uri Base64 encoded URI.
     */
    function _tokenURI(uint256 tokenId_) external view returns (string memory uri);
}
