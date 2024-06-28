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
 * ## Auction & Bid
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
     * @notice Add address to whitelist.
     *
     * @param tokenId_ Token ID.
     * @param address_ Address of user will be added into whitelist.
     */
    function addToWhitelist(uint256 tokenId_, address address_) external;

    /**
     * @notice Remove address from whitelist.
     *
     * @param tokenId_ Token ID.
     * @param address_ Address of user will be removed from whitelist.
     */
    function removeFromWhitelist(uint256 tokenId_, address address_) external;

    //////////////////////////////
    /// Board
    //////////////////////////////

    /**
     * @notice Mint a new board (NFT).
     *
     * @param to_ Address of the board owner.
     * @param taxRate_ Tax rate of the new board.
     * @param epochInterval_ Epoch interval of the new board.
     *
     * @return tokenId Token ID of the new board.
     */
    function newBoard(address to_, uint256 taxRate_, uint256 epochInterval_) external returns (uint256 tokenId);

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
    ) external returns (address[] memory highestBidders, uint256[] memory prices, uint256[] memory taxes);

    /**
     * @notice Place bid on a board auction.
     *
     * @param tokenId_ Token ID.
     * @param epoch_ Epoch.
     * @param amount_ Amount of a bid.
     */
    function placeBid(uint256 tokenId_, uint256 epoch_, uint256 amount_) external payable;

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

    //////////////////////////////
    /// Tax & Withdraw
    //////////////////////////////

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
     */
    function withdrawTax() external returns (uint256 tax);

    /**
     * @notice Withdraw bid that were not won by auction id;
     *
     * @param tokenId_ Token ID.
     * @param epoch_ Epoch.
     */
    function withdrawBid(uint256 tokenId_, uint256 epoch_) external;
}
