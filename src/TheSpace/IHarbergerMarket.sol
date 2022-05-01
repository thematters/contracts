//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./IHarbergerRegistry.sol";

/**
 * @notice ERC721-compatible contract that allows token to be traded under Harberger tax.
 * @dev Market attaches one ERC20 contract as currency.
 */
interface IHarbergerMarket {
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
    /// Configuration / Admin
    //////////////////////////////

    /**
     * @notice Update current tax configuration.
     * @dev ADMIN_ROLE only.
     * @param option_ Field of config been updated.
     * @param value_ New value after update.
     */
    function setTaxConfig(IHarbergerRegistry.ConfigOptions option_, uint256 value_) external;

    /**
     * @notice Withdraw all available treasury.
     * @dev TREASURY_ROLE only.
     */
    function withdrawTreasury(address to) external;

    //////////////////////////////
    /// Trading
    //////////////////////////////

    /**
     * @notice Returns the current price of a token by id.
     * @param tokenId_ Id of token been queried.
     * @return price Current price.
     */
    function getPrice(uint256 tokenId_) external view returns (uint256 price);

    /**
     * @notice Set the current price of a token with id. Triggers tax settle first, price is succefully updated after tax is successfully collected.
     * @dev Only token owner or approved operator. Throw `Unauthorized` or `ERC721: operator query for nonexistent token` error. Emits a {Price} event if update is successful.
     * @param tokenId_ Id of token been updated.
     * @param price_ New price to be updated.
     */
    function setPrice(uint256 tokenId_, uint256 price_) external;

    /**
     * @notice Returns the current owner of an Harberger property with token id.
     * @dev If token does not exisit, return address(0) and user can bid the token as usual.
     * @param tokenId_ Id of token been queried.
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
     * @param tokenId_ Id of token been queried.
     * @return amount Current amount of tax that needs to be paid.
     */
    function getTax(uint256 tokenId_) external view returns (uint256 amount);

    /**
     * @notice Calculate amount of tax that can be collected, and determine if token should be defaulted.
     * @param tokenId_ Id of token been queried.
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
     * @param tokenId_ Id of token been queried.
     * @param amount Amount of UBI available to be collected
     */
    function ubiAvailable(uint256 tokenId_) external view returns (uint256 amount);

    /**
     * @notice Withdraw all UBI on given token.
     * @param tokenId_ Id of token been withdrawn.
     */
    function withdrawUbi(uint256 tokenId_) external;
}
