//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Property.sol";

/**
 * @dev Market place with Harberger tax, inherits from `IPixelCanvas`. Market creates one ERC721 contract as property, and attaches one ERC20 contract as currency.
 */
abstract contract HarbergerMarket is Multicall, Ownable {
    error PriceTooLow();
    error Unauthorized();
    error TokenNotExists();

    /**
     * @dev Tax record of token. Use block number to record tax collection time.
     *
     * TODO: more efficient storage scheme, see: https://medium.com/@novablitz/storing-structs-is-costing-you-gas-774da988895e
     */
    struct TaxRecord {
        uint256 price;
        uint256 lastTaxCollection;
        uint256 ubiWithdrawn;
    }

    /**
     * @dev Tax configuration of market.
     * - taxRate: Tax rate in bps every 1000 blocks
     * - treasuryShare: Share to treasury in bps.
     */
    enum ConfigOptions {
        taxRate,
        treasuryShare
    }

    /**
     * @dev Emitted when a token changes price.
     */
    event Price(uint256 indexed tokenId, uint256 price, address owner);

    /**
     * @dev Emitted when tax configuration updates.
     */
    event Config(ConfigOptions indexed option, uint256 value);

    /**
     * @dev Emitted when tax is collected.
     */
    event Tax(uint256 indexed tokenId, uint256 amount);

    /**
     * @dev Emitted when UBI is distributed.
     */
    event UBI(uint256 indexed tokenId, uint256 amount);

    /**
     * @dev Tax record of each token.
     */
    mapping(uint256 => TaxRecord) public taxRecord;

    // Setting for tax config
    mapping(ConfigOptions => uint256) public taxConfig;

    // total accumulated UBI
    uint256 public accumulatedUBI;

    // total token supply
    uint256 public totalSupply = 1000000;

    /**
     * @dev Tradable propertys created by this contract.
     */
    Property public property;

    /**
     * @dev ERC20 token used as currency
     */
    ERC20 public currency;

    /**
     * @dev Create Property contract, setup attached currency contract, setup tax rate
     */
    constructor(
        string memory propertyName,
        string memory propertySymbol,
        address currencyAddress
    ) {
        // initialize Property contract with current contract as market
        property = new Property(propertyName, propertySymbol, address(this), totalSupply);

        // initialize currency contract
        currency = ERC20(currencyAddress);

        // default config
        taxConfig[ConfigOptions.taxRate] = 10;
        taxConfig[ConfigOptions.treasuryShare] = 500;
    }

    /**
     * @dev Set the current price of an Harberger property with token id.
     *
     * Emits a {Price} event.
     */
    function setTaxConfig(ConfigOptions option, uint256 value) external onlyOwner {
        taxConfig[option] = value;

        emit Config(option, value);
    }

    // TODO: withraw community treasury

    /**
     * @dev Set the current price of an Harberger property with token id.
     *
     * Emits a {Price} event.
     */
    function setPrice(uint256 tokenId, uint256 price) external {
        if (!property.isApprovedOrOwner(msg.sender, tokenId)) revert Unauthorized();
        if (price == this.getPrice(tokenId)) return;

        bool success = this.collectTax(tokenId);
        if (success) _setPrice(tokenId, price);
    }

    /**
     * @dev Returns the current price of an Harberger property with token id.
     */
    function getPrice(uint256 tokenId) external view returns (uint256 price) {
        return taxRecord[tokenId].price;
    }

    /**
     * @dev Returns the current owner of an Harberger property with token id.
     */
    function getOwner(uint256 tokenId) external view returns (address owner) {
        return property.ownerOf(tokenId);
    }

    /**
     * @dev calculate tax for a token
     */
    function getTax(uint256 tokenId) external view returns (uint256) {
        // calculate tax
        // 1000 for every 1000 blocks, 10000 for conversion from bps
        return
            (this.getPrice(tokenId) *
                taxConfig[ConfigOptions.taxRate] *
                (block.number - taxRecord[tokenId].lastTaxCollection)) / (1000 * 10000);
    }

    /**
     * @dev Purchase property with bid higher than current price. Clear tax for owner before transfer.
     * TODO: check security implications
     */
    function bid(uint256 tokenId, uint256 price) external {
        if (property.exists(tokenId)) {
            if (property.ownerOf(tokenId) == msg.sender) return;
            uint256 askPrice = this.getPrice(tokenId);
            if (price < askPrice) revert PriceTooLow();

            // collect tax
            bool success = this.collectTax(tokenId);

            if (success) {
                // successfully clear tax
                currency.transferFrom(msg.sender, property.ownerOf(tokenId), askPrice);
                property.safeTransferByMarket(property.ownerOf(tokenId), msg.sender, tokenId);

                return;
            }
        }

        // if token does not exists yet, or token is defaulted
        // mint token to current sender for free
        property.mint(msg.sender, tokenId);
        // update tax record
        taxRecord[tokenId].lastTaxCollection = block.number;
    }

    /**
     * @dev Collect outstanding property tax for a given token, put token on tax sale if obligation not met.
     *
     * Emits a {Tax} event and a {Price} event (when properties are put on tax sale).
     */
    function collectTax(uint256 tokenId) external returns (bool) {
        if (!property.exists(tokenId)) revert TokenNotExists();

        uint256 tax = this.getTax(tokenId);
        if (tax > 0) {
            // calculate collectable amount
            address taxpayer = property.ownerOf(tokenId);
            uint256 allowance = currency.allowance(taxpayer, address(this));
            uint256 balance = currency.balanceOf(taxpayer);
            uint256 collectable = _min(allowance, balance);

            // calculate amount to be collected, the smaller one of tax and collectable
            // then update accumulatedUBI
            uint256 collecting = _min(collectable, tax);

            if (collecting > 0) {
                currency.transferFrom(property.ownerOf(tokenId), address(this), collecting);
                emit Tax(tokenId, collecting);
                // update accumulated ubi
                accumulatedUBI += collecting;
            }

            // default if tax is not fully collected
            if (tax > collectable) {
                // default
                _default(tokenId);
                return false;
            } else {
                // collect tax
                taxRecord[tokenId].lastTaxCollection = block.number;
                return true;
            }
        } else {
            // no tax for price 0
            taxRecord[tokenId].lastTaxCollection = block.number;
            return true;
        }
    }

    function ubiAvailable(uint256 tokenId) external view returns (uint256) {
        return
            ((accumulatedUBI * (10000 - taxConfig[ConfigOptions.treasuryShare])) / 10000) /
            totalSupply -
            taxRecord[tokenId].ubiWithdrawn;
    }

    function withdrawUbi(uint256 tokenId) external {
        uint256 ubi = this.ubiAvailable(tokenId);

        if (ubi > 0) {
            currency.transferFrom(address(this), property.ownerOf(tokenId), ubi);
            taxRecord[tokenId].ubiWithdrawn += ubi;

            emit UBI(tokenId, ubi);
        }
    }

    function _default(uint256 tokenId) internal {
        property.burn(tokenId);
        _setPrice(tokenId, 0);
    }

    function _setPrice(uint256 tokenId, uint256 price) internal {
        // update price in tax record
        taxRecord[tokenId].price = price;

        address owner = property.exists(tokenId) ? property.ownerOf(tokenId) : address(0);

        // emit events
        emit Price(tokenId, price, owner);
    }

    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}
