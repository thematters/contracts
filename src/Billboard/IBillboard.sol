//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "./IBillboardRegistry.sol";

interface IBillboard {
    //////////////////////////////
    /// Error
    //////////////////////////////

    error AdminNotFound();

    error InvalidAddress();

    error Unauthorized(string type_);

    //////////////////////////////
    /// Upgradability
    //////////////////////////////

    /**
     * @notice Switch the registry logic contract to another one.
     *
     * @param contract_ Address of new registry logic contract.
     */
    function upgradeRegistry(address contract_) external;

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
    function mintBoard(address to_) external;

    /**
     * @notice Get a board data.
     *
     * @param tokenId_ Token ID of a board.
     *
     * @return board Board data.
     */
    function getBoard(uint256 tokenId_) external view returns (IBillboardRegistry.Board memory board);

    /**
     * @notice Set the name of a board.
     *
     * @param tokenId_ Token ID of a board.
     * @param name_ Board name.
     */
    function setBoardName(uint256 tokenId_, string memory name_) external;

    /**
     * @notice Set the description of a board.
     *
     * @param tokenId_ Token ID of a board.
     * @param description_ Board description.
     */
    function setBoardDescription(uint256 tokenId_, string memory description_) external;

    /**
     * @notice Set the location of a board.
     *
     * @param tokenId_ Token ID of a board.
     * @param location_ Digital address where a board located.
     */
    function setBoardLocation(uint256 tokenId_, string memory location_) external;

    /**
     * @notice Set the content URI of a board.
     *
     * @param tokenId_ Token ID of a board.
     * @param uri_ Content URI of a board.
     */
    function setBoardContentURI(uint256 tokenId_, string memory uri_) external;

    /**
     * @notice Set the redirect URI of a board when users clicking.
     *
     * @param tokenId_ Token ID of a board.
     * @param redirectURI_ Redirect URI of a board.
     */
    function setBoardRedirectURI(uint256 tokenId_, string memory redirectURI_) external;

    //////////////////////////////
    /// Auction
    //////////////////////////////

    /**
     * @notice Get last cleared auction of a board.
     *
     * @param tokenId_ Token ID of a board.
     */
    function getAuction(uint256 tokenId_) external view returns (IBillboardRegistry.Auction memory auction);

    /**
     * @notice Get auction of a board by auction ID.
     *
     * @param tokenId_ Token ID of a board.
     * @param auctionId_ Auction ID of a board.
     */
    function getAuction(uint256 tokenId_, uint256 auctionId_)
        external
        view
        returns (IBillboardRegistry.Auction memory auction);

    /**
     * @notice Clear a board auction.
     *
     * 1. update Board.auctionId
     * 2. update Auction.startAt, endAt
     * 3. update Bid.isWon
     * 4. transfer bid price to last Auction.higghestBidder
     * 5. transfer bid tax to TaxTreasury
     * ...
     *
     * @param tokenId_ Token ID of a board.
     */
    function clearAuction(uint256 tokenId_) external;

    /**
     * @notice Place bid for a board.
     *
     * @param tokenId_ Token ID of a board.
     * @param amount_ Amount of a bid.
     */
    function placeBid(uint256 tokenId_, uint256 amount_) external;

    /**
     * @notice Get bid of a board auction.
     *
     * @param tokenId_ Token ID of a board.
     * @param bidder_ Address of a bidder.
     *
     * @return bid Bid of a board.
     */
    function getBid(uint256 tokenId_, address bidder_) external view returns (IBillboardRegistry.Bid memory bid);

    /**
     * @notice Get bid of a board auction by auction ID.
     *
     * @param tokenId_ Token ID of a board.
     * @param bidder_ Address of a bidder.
     * @param auctionId_ Auction ID of a board.
     *
     * @return bid Bid of a board.
     */
    function getBid(
        uint256 tokenId_,
        address bidder_,
        uint256 auctionId_
    ) external view returns (IBillboardRegistry.Bid memory bid);

    /**
     * @notice Get bids of a board auction.
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
            IBillboardRegistry.Bid[] memory bids
        );

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
    function getBidsByBoard(
        uint256 tokenId_,
        uint256 auctionId_,
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
        );

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
     * @notice Get the global tax rate.
     *
     * @return taxRate Tax rate.
     */
    function getTaxRate() external view returns (uint256 taxRate);

    /**
     * @notice Withdraw accumulated taxation of a board.
     *
     * @param tokenId_ Token ID of a board.
     * @param owner_ Address of a treasury owner.
     */
    function withdrawTax(uint256 tokenId_, address owner_) external;

    /**
     * @notice Withdraw bid that were not won by auction id;
     *
     * @param tokenId_ Token ID of a board.
     * @param auctionId_ Auction ID of a board.
     * @param bidder_ Address of a auction bidder.
     */
    function withdrawBid(
        uint256 tokenId_,
        uint256 auctionId_,
        address bidder_
    ) external;
}
