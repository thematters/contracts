//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @notice ERC721-compatible contract that allows token to be traded under Harberger tax.
 * @dev Market attaches one ERC20 contract as currency.
 */
interface IHarbergerMarket is IERC721 {
    /**
     * Error types
     */

    /**
     * @dev Price too low to bid the given token.
     */
    error PriceTooLow();

    /**
     * @dev Sender is not authorized for given operation.
     */
    error Unauthorized();

    /**
     * @dev The give token does not exist and needs to be minted first via bidding.
     */
    error TokenNotExists();

    /**
     * @dev Token id is out of range.
     * @param min Lower range of possible token id.
     * @param max Higher range of possible token id.
     */
    error InvalidTokenId(uint256 min, uint256 max);

    /**
     * Event types
     */

    /**
     * @notice A token updated price.
     * @param tokenId Id of token that updated price.
     * @param price New price after update.
     * @param owner Token owner during price update.
     */
    event Price(uint256 indexed tokenId, uint256 price, address indexed owner);

    /**
     * @notice Global configuration for tax is updated.
     * @param option Field of config been updated.
     * @param value New value after update.
     */
    event Config(ConfigOptions indexed option, uint256 value);

    /**
     * @notice Tax is collected for a token.
     * @param tokenId Id of token that has been taxed.
     * @param taxpayer user address who has paid the tax.
     * @param amount Amount of tax been collected.
     */
    event Tax(uint256 indexed tokenId, address indexed taxpayer, uint256 amount);

    /**
     * @notice UBI (universal basic income) is withdrawn for a token.
     * @param tokenId Id of token that UBI has been withdrawn for.
     * @param recipient user address who got this withdrawn UBI.
     * @param amount Amount of UBI withdrawn.
     */
    event UBI(uint256 indexed tokenId, address indexed recipient, uint256 amount);

    /**
     * @notice A token has been succefully bid.
     * @param tokenId Id of token that has been bid.
     * @param from Original owner before bid.
     * @param to New owner after bid.
     * @param amount Amount of currency used for bidding.
     */
    event Bid(uint256 indexed tokenId, address indexed from, address indexed to, uint256 amount);

    /**
     * @dev Options for global tax configuration.
     * @param taxRate: Tax rate in bps every 1000 blocks
     * @param treasuryShare: Share to treasury in bps.
     * @param mintTax: Tax to mint a token. It should be non-zero to prevent attacker constantly mint, default and mint token again.
     */
    enum ConfigOptions {
        taxRate,
        treasuryShare,
        mintTax
    }

    /**
     * Configuration / Admin
     */

    /**
     * @notice Update current tax configuration.
     * @dev ADMIN_ROLE only.
     * @param option_ Field of config been updated.
     * @param value_ New value after update.
     */
    function setTaxConfig(ConfigOptions option_, uint256 value_) external;

    /**
     * @notice Withdraw all available treasury.
     * @dev TREASURY_ROLE only.
     */
    function withdrawTreasury(address to) external;

    /**
     * Trading
     */

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

    /**
     * Tax & UBI
     */

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
