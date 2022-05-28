//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @title The interface for `TheSpaceRegistry` contract.
 * @notice Storage contract for `TheSpace` contract.
 * @dev It stores all states related to the market, and is owned by the TheSpace contract.
 * @dev The market contract can be upgraded by changing the owner of this contract to the new implementation contract.
 */
interface ITheSpaceRegistry is IERC721Enumerable {
    //////////////////////////////
    /// Error types
    //////////////////////////////

    /**
     * @notice Token id is out of range.
     * @param min Lower range of possible token id.
     * @param max Higher range of possible token id.
     */
    error InvalidTokenId(uint256 min, uint256 max);

    //////////////////////////////
    /// Event types
    //////////////////////////////

    /**
     * @notice A token updated price.
     * @param tokenId Id of token that updated price.
     * @param price New price after update.
     * @param owner Token owner during price update.
     */
    event Price(uint256 indexed tokenId, uint256 price, address indexed owner);

    /**
     * @notice Global configuration is updated.
     * @param option Field of config been updated.
     * @param value New value after update.
     */
    event Config(ConfigOptions indexed option, uint256 value);

    /**
     * @notice Total is updated.
     * @param previousSupply Total supply amount before update.
     * @param newSupply New supply amount after update.
     */
    event TotalSupply(uint256 previousSupply, uint256 newSupply);

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
     * @notice Treasury is withdrawn.
     * @param recipient address who got this withdrawn treasury.
     * @param amount Amount of withdrawn.
     */
    event Treasury(address indexed recipient, uint256 amount);

    /**
     * @notice A token has been succefully bid.
     * @param tokenId Id of token that has been bid.
     * @param from Original owner before bid.
     * @param to New owner after bid.
     * @param amount Amount of currency used for bidding.
     */
    event Deal(uint256 indexed tokenId, address indexed from, address indexed to, uint256 amount);

    /**
     * @notice Emitted when the color of a pixel is updated.
     * @param tokenId Id of token that has been bid.
     * @param color Color index defined by client.
     * @param owner Token owner.
     */
    event Color(uint256 indexed tokenId, uint256 indexed color, address indexed owner);

    //////////////////////////////
    /// Data structure
    //////////////////////////////

    /**
     * @notice Options for global tax configuration.
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
     * @notice Record of each token.
     * @param price Current price.
     * @param lastTaxCollection Block number of last tax collection.
     * @param ubiWithdrawn Amount of UBI been withdrawn.
     */
    struct TokenRecord {
        uint256 price;
        uint256 lastTaxCollection;
        uint256 ubiWithdrawn;
    }

    /**
     * @notice Global state of tax and treasury.
     * @param accumulatedUBI Total amount of currency allocated for UBI.
     * @param accumulatedTreasury Total amount of currency allocated for treasury.
     * @param treasuryWithdrawn Total amount of treasury been withdrawn.
     */
    struct TreasuryRecord {
        uint256 accumulatedUBI;
        uint256 accumulatedTreasury;
        uint256 treasuryWithdrawn;
    }

    /**
     * @dev Packed pixel info.
     */
    struct Pixel {
        uint256 tokenId;
        uint256 price;
        uint256 lastTaxCollection;
        uint256 ubi;
        address owner;
        uint256 color;
    }

    //////////////////////////////
    /// Getters & Setters
    //////////////////////////////

    /**
     * @notice Update total supply of ERC721 token.
     * @param totalSupply_ New amount of total supply.
     */
    function setTotalSupply(uint256 totalSupply_) external;

    /**
     * @notice Update global tax settings.
     * @param option_ Tax config options, see {ConfigOptions} for detail.
     * @param value_ New value for tax setting.
     */
    function setTaxConfig(ConfigOptions option_, uint256 value_) external;

    /**
     * @notice Update UBI and treasury.
     * @param accumulatedUBI_ Total amount of currency allocated for UBI.
     * @param accumulatedTreasury_ Total amount of currency allocated for treasury.
     * @param treasuryWithdrawn_ Total amount of treasury been withdrawn.
     */
    function setTreasuryRecord(
        uint256 accumulatedUBI_,
        uint256 accumulatedTreasury_,
        uint256 treasuryWithdrawn_
    ) external;

    /**
     * @notice Set record for a given token.
     * @param tokenId_ Id of token to be set.
     * @param price_ Current price.
     * @param lastTaxCollection_ Block number of last tax collection.
     * @param ubiWithdrawn_ Amount of UBI been withdrawn.
     */
    function setTokenRecord(
        uint256 tokenId_,
        uint256 price_,
        uint256 lastTaxCollection_,
        uint256 ubiWithdrawn_
    ) external;

    /**
     * @notice Set color for a given token.
     * @param tokenId_ Token id to be set.
     * @param color_ Color Id.
     * @param owner_ Token owner.
     */
    function setColor(
        uint256 tokenId_,
        uint256 color_,
        address owner_
    ) external;

    //////////////////////////////
    /// Event emission
    //////////////////////////////

    /**
     * @dev Emit {Tax} event
     */
    function emitTax(
        uint256 tokenId_,
        address taxpayer_,
        uint256 amount_
    ) external;

    /**
     * @dev Emit {Price} event
     */
    function emitPrice(
        uint256 tokenId_,
        uint256 price_,
        address operator_
    ) external;

    /**
     * @dev Emit {UBI} event
     */
    function emitUBI(
        uint256 tokenId_,
        address recipient_,
        uint256 amount_
    ) external;

    /**
     * @dev Emit {Treasury} event
     */
    function emitTreasury(address recipient_, uint256 amount_) external;

    /**
     * @dev Emit {Deal} event
     */
    function emitDeal(
        uint256 tokenId_,
        address from_,
        address to_,
        uint256 amount_
    ) external;

    //////////////////////////////
    /// ERC721 property related
    //////////////////////////////

    /**
     * @dev Mint an ERC721 token.
     */
    function mint(address to_, uint256 tokenId_) external;

    /**
     * @dev Burn an ERC721 token.
     */
    function burn(uint256 tokenId_) external;

    /**
     * @dev Perform ERC721 token transfer by market contract.
     */
    function safeTransferByMarket(
        address from_,
        address to_,
        uint256 tokenId_
    ) external;

    /**
     * @dev If an ERC721 token has been minted.
     */
    function exists(uint256 tokenId_) external view returns (bool);

    /**
     * @dev If an address is allowed to transfer an ERC721 token.
     */
    function isApprovedOrOwner(address spender_, uint256 tokenId_) external view returns (bool);

    //////////////////////////////
    /// ERC20 currency related
    //////////////////////////////

    /**
     * @dev Perform ERC20 token transfer by market contract.
     */
    function transferCurrency(address to_, uint256 amount_) external;

    /**
     * @dev Perform ERC20 token transferFrom by market contract.
     */
    function transferCurrencyFrom(
        address from_,
        address to_,
        uint256 amount_
    ) external;
}
