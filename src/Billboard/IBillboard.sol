//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "./IBillboardAuction.sol";
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
     * @notice Switch the auction logic contract to another one.
     *
     * @param contract_ Address of new auction logic contract.
     */
    function upgradeAuction(address contract_) external;

    /**
     * @notice Switch the registry logic contract to another one.
     *
     * @param contract_ Address of new registry logic contract.
     */
    function upgradeRegistry(address contract_) external;

    /**
     * @notice Toggle for operation access.
     *
     * @param value_ Value of access state.
     */
    function setIsOpened(bool value_) external;

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
     * @notice Set the redirect link of a board when users clicking.
     *
     * @param tokenId_ Token ID of a board.
     * @param redirectLink_ Redirect link of a board.
     */
    function setBoardRedirectLink(uint256 tokenId_, string memory redirectLink_) external;

    //////////////////////////////
    /// Auction
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
     * @notice Place bid for a board.
     *
     * @param tokenId_ Token ID of a board.
     * @param amount_ Amount of a bid.
     */
    function placeBid(uint256 tokenId_, uint256 amount_) external;

    /**
     * @notice Get a bid of a board.
     *
     * @param tokenId_ Token ID of a board.
     * @param bidder_ Address of a bidder.
     *
     * @return bid Bid of a board.
     */
    function getBid(uint256 tokenId_, address bidder_) external view returns (IBillboardAuction.Bid memory bid);

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
            IBillboardAuction.Bid[] memory bids
        );

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
     */
    function withdraw(uint256 tokenId_) external;
}
