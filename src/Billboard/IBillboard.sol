//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "./IBillboardRegistry.sol";

/**
 * @title The interface for `Billboard` contract
 * @notice The on-chain billboard system transforms platform attention into NFT billboards based on Harberger tax auctions. Empowering creators with a fair share of tax revenue through quadratic voting.
 *
 * ## Billboard
 * - User (whitelisted) can mint a billboard: call `mintBoard`.
 * - Owner of a billboard can set the AD data of a billboard: call `setBoardName`, `setBoardDescription` and `setBoardLocation`.
 * - Tenant of a billboard can set the AD data of a billboard: call `setBoardContentURI` and `setBoardRedirectURI`.
 *
 * ## Auction
 * - User needs to call `approve` on currency (USDT) contract before starting.
 * - User can place a bid on a billboard: call `placeBid`.
 * - User can clear auction on a billboard: call `clearAuction`.
 * - User can withdraw bid from a billboard: call `withdrawBid`.
 *
 * ## Tax
 * - Admin of this contract can set global tax rate: call `setTaxRate`.
 * - Owner of a billbaord can withdraw tax: call `withdrawTax`.
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
     * @notice Toggle for operation access.
     *
     * @param value_ Value of access state.
     */
    function setIsOpened(bool value_) external;

    /**
     * @notice Add address to white list.
     *
     * @param value_ Address of user will be added into white list.
     */
    function addToWhitelist(address value_) external;

    /**
     * @notice Remove address from white list.
     *
     * @param value_ Address of user will be removed from white list.
     */
    function removeFromWhitelist(address value_) external;

    //////////////////////////////
    /// Board
    //////////////////////////////

    /**
     * @notice Mint a new board (NFT).
     *
     * @param to_ Address of the new board receiver.
     */
    function mintBoard(address to_) external returns (uint256 tokenId);

    /**
     * @notice Get a board data.
     *
     * @param tokenId_ Token ID of a board.
     *
     * @return board Board data.
     */
    function getBoard(uint256 tokenId_) external view returns (IBillboardRegistry.Board memory board);

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
     * @notice Get auction of a board by auction ID.
     *
     * @param tokenId_ Token ID of a board.
     * @param auctionId_ Auction ID of a board.
     */
    function getAuction(
        uint256 tokenId_,
        uint256 auctionId_
    ) external view returns (IBillboardRegistry.Auction memory auction);

    /**
     * @notice Clear the next auction of a board.
     *
     * @param tokenId_ Token ID of a board.
     */
    function clearAuction(uint256 tokenId_) external returns (uint256 price, uint256 tax);

    /**
     * @notice Clear the next auction of mutiple boards.
     *
     * @param tokenIds_ Token IDs of boards.
     */
    function clearAuctions(
        uint256[] calldata tokenIds_
    ) external returns (uint256[] memory prices, uint256[] memory taxes);

    /**
     * @notice Place bid for the next auction of a board.
     *
     * @param tokenId_ Token ID of a board.
     * @param amount_ Amount of a bid.
     */
    function placeBid(uint256 tokenId_, uint256 amount_) external payable;

    /**
     * @notice Get bid of a board auction by auction ID.
     *
     * @param tokenId_ Token ID of a board.
     * @param auctionId_ Auction ID of a board.
     * @param bidder_ Address of a bidder.
     *
     * @return bid Bid of a board.
     */
    function getBid(
        uint256 tokenId_,
        uint256 auctionId_,
        address bidder_
    ) external view returns (IBillboardRegistry.Bid memory bid);

    /**
     * @notice Get bids of a board auction by auction ID.
     *
     * @param tokenId_ Token ID of a board.
     * @param auctionId_ Auction ID of a board.
     * @param limit_ Limit of returned bids.
     * @param offset_ Offset of returned bids.
     *
     * @return total Total number of bids.
     * @return limit Limit of returned bids.
     * @return offset Offset of returned bids.
     * @return bids Bids of a board.
     */
    function getBids(
        uint256 tokenId_,
        uint256 auctionId_,
        uint256 limit_,
        uint256 offset_
    ) external view returns (uint256 total, uint256 limit, uint256 offset, IBillboardRegistry.Bid[] memory bids);

    //////////////////////////////
    /// Tax & Withdraw
    //////////////////////////////

    /**
     * @notice Get the global tax rate.
     *
     * @return taxRate Tax rate.
     */
    function getTaxRate() external view returns (uint256 taxRate);

    /**
     * @notice Set the global tax rate.
     *
     * @param taxRate_ Tax rate.
     */
    function setTaxRate(uint256 taxRate_) external;

    /**
     * @notice Calculate tax of a bid.
     *
     * @param amount_ Amount of a bid.
     */
    function calculateTax(uint256 amount_) external returns (uint256 tax);

    /**
     * @notice Withdraw accumulated taxation of a board.
     *
     */
    function withdrawTax() external returns (uint256 tax);

    /**
     * @notice Withdraw bid that were not won by auction id;
     *
     * @param tokenId_ Token ID of a board.
     * @param auctionId_ Auction ID of a board.
     */
    function withdrawBid(uint256 tokenId_, uint256 auctionId_) external;

    //////////////////////////////
    /// Block
    //////////////////////////////

    /**
     * @notice Get the global block number per day.
     *
     * @return blocksPerDay Block number per day.
     */
    function getBlocksPerDay() external view returns (uint64 blocksPerDay);

    /**
     * @notice Set the global block number per day.
     *
     * @param blocksPerDay_ Block number per day.
     */
    function setBlocksPerDay(uint64 blocksPerDay_) external;
}
