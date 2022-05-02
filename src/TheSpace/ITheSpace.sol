//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ITheSpaceRegistry.sol";

/**
 * @title The interface for `TheSpace` contract
 * @notice _The Space_ is a pixel space owned by a decentralized autonomous organization (DAO), where members can tokenize, own, trade and color pixels.
 *
 * Pixels are tokenized as ERC721 tokens and traded under Harberger tax, while members receive dividend based on the share of pixels they own.
 *
 * #### Trading
 * - User needs to call `approve` on currency contract before starting. If there is not sufficient allowance for taxing, the corresponding assets are defaulted.
 * - User buy pixel: call [`bid` function](./ITheSpace.md).
 * - User set pixel price: call [`setPrice` function](./ITheSpace.md).
 *
 * @dev This contract holds the logic of market place, while read from and write into {TheSpaceRegistry}, which is the storage contact.
 * @dev This contract owns a {TheSpaceRegistry} contract for storage, and can be updated by transfering ownership to a new implementation contract.
 */

interface ITheSpace {
    //////////////////////////////
    /// Error types
    //////////////////////////////

    /**
     * @dev Price too low to bid the given token.
     */
    error PriceTooLow();

    /**
     * @dev Price too high to set.
     */
    error PriceTooHigh();

    /**
     * @dev Sender is not authorized for given operation.
     */
    error Unauthorized();

    /**
     * @dev The give token does not exist and needs to be minted first via bidding.
     */
    error TokenNotExists();

    //////////////////////////////
    /// Upgradability
    //////////////////////////////

    /**
     * @notice Switch logic contract to another one.
     * @param newImplementation address of new logic contract.
     */
    function upgradeTo(address newImplementation) external;

    //////////////////////////////
    /// Configuration / Admin
    //////////////////////////////

    /**
     * @notice Update current tax configuration.
     * @dev Only `Role.marketAdmin`.
     * @param option_ Field of config been updated.
     * @param value_ New value after update.
     */
    function setTaxConfig(ITheSpaceRegistry.ConfigOptions option_, uint256 value_) external;

    /**
     * @notice Withdraw all available treasury to a given address (DAO treasury).
     * @dev Only `Role.treasuryAdmin`.
     */
    function withdrawTreasury(address to) external;

    //////////////////////////////
    /// Pixel
    //////////////////////////////

    /**
     * @notice Bid pixel, then set price and color.
     * @param tokenId_ Token id to be bid and set.
     * @param bidPrice_ Bid price.
     * @param newPrice_ New price to be set.
     * @param color_ Color to be set.
     */
    function setPixel(
        uint256 tokenId_,
        uint256 bidPrice_,
        uint256 newPrice_,
        uint256 color_
    ) external;

    /**
     * @notice Get pixel info.
     * @param tokenId_ Token id to be queried.
     * @return pixel Packed pixel info.
     */
    function getPixel(uint256 tokenId_) external view returns (ITheSpaceRegistry.Pixel memory pixel);

    /**
     * @notice Set color for a pixel.
     * @param tokenId_ Token id to be set.
     * @param color_ Color to be set.
     */
    function setColor(uint256 tokenId_, uint256 color_) external;

    /**
     * @notice Get color for a pixel.
     * @param tokenId_ Token id to be queried.
     * @return color Color.
     */
    function getColor(uint256 tokenId_) external view returns (uint256 color);

    /**
     * @notice Get pixels owned by a given address.
     * @param owner_ Owner address.
     * @param limit_ Limit of returned pixels.
     * @param offset_ Offset of returned pixels.
     * @return total Total number of pixels.
     * @return limit Limit of returned pixels.
     * @return offset Offset of returned pixels.
     * @return pixels Packed pixels.
     * @dev offset-based pagination
     */
    function getPixelsByOwner(
        address owner_,
        uint256 limit_,
        uint256 offset_
    )
        external
        view
        returns (
            uint256 total,
            uint256 limit,
            uint256 offset,
            ITheSpaceRegistry.Pixel[] memory pixels
        );

    //////////////////////////////
    /// Trading
    //////////////////////////////

    /**
     * @notice Returns the current price of a token by id.
     * @param tokenId_ Token id to be queried.
     * @return price Current price.
     */
    function getPrice(uint256 tokenId_) external view returns (uint256 price);

    /**
     * @notice Set the current price of a token with id. Triggers tax settle first, price is succefully updated after tax is successfully collected.
     * @dev Only token owner or approved operator.
     * @dev Throw `Unauthorized` or `ERC721: operator query for nonexistent token` error.
     * @dev Emits a {Price} event if update is successful.
     * @param tokenId_ Id of token been updated.
     * @param price_ New price to be updated.
     */
    function setPrice(uint256 tokenId_, uint256 price_) external;

    /**
     * @notice Returns the current owner of an Harberger property with token id.
     * @dev If token does not exisit, return zero address and user can bid the token as usual.
     * @param tokenId_ Token id to be queried.
     * @return owner Current owner address.
     */
    function getOwner(uint256 tokenId_) external view returns (address owner);

    /**
     * @notice Purchase property with bid higher than current price. If bid price is higher than ask price, only ask price will be deducted.
     * @dev Clear tax for owner before transfer.
     * @param tokenId_ Id of token been bid.
     * @param price_ Bid price.
     */
    function bid(uint256 tokenId_, uint256 price_) external;

    //////////////////////////////
    /// Tax & UBI
    //////////////////////////////

    /**
     * @notice Calculate outstanding tax for a token.
     * @param tokenId_ Token id to be queried.
     * @return amount Current amount of tax that needs to be paid.
     */
    function getTax(uint256 tokenId_) external view returns (uint256 amount);

    /**
     * @notice Calculate amount of tax that can be collected, and determine if token should be defaulted.
     * @param tokenId_ Token id to be queried.
     * @return collectable Amount of currency that can be collected, considering balance and allowance.
     * @return shouldDefault Whether current token should be defaulted.
     */
    function evaluateOwnership(uint256 tokenId_) external view returns (uint256 collectable, bool shouldDefault);

    /**
     * @notice Collect outstanding tax of a token and default it if needed.
     * @dev Anyone can trigger this function. It could be desirable for the developer team to trigger it once a while to make sure all tokens meet their tax obligation.
     * @param tokenId_ Id of token been settled.
     * @return success Whether tax is fully collected without token been defaulted.
     */
    function settleTax(uint256 tokenId_) external returns (bool success);

    /**
     * @notice Amount of UBI available for withdraw on given token.
     * @param tokenId_ Token id to be queried.
     * @param amount Amount of UBI available to be collected
     */
    function ubiAvailable(uint256 tokenId_) external view returns (uint256 amount);

    /**
     * @notice Withdraw all UBI on given token.
     * @param tokenId_ Id of token been withdrawn.
     */
    function withdrawUbi(uint256 tokenId_) external;

    /**
     * @notice Perform before `safeTransfer` and `safeTransferFrom` by registry contract.
     * @dev Collect tax and set price.
     * @param tokenId_ Token id to be transferred.
     * @return success Whether tax is fully collected without token been defaulted.
     */
    function beforeTransferByRegistry(uint256 tokenId_) external returns (bool success);
}
