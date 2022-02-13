//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

import "./Property.sol";

/**
 * @dev Market place with Harberger tax, inherits from `IPixelCanvas`. Market creates one ERC721 contract as property, and attaches one ERC20 contract as currency.
 */
abstract contract HarbergerMarket is Multicall {
    /**
     * @dev Emitted when a token changes price.
     */
    event Price(uint256 indexed tokenId, uint256 price);

    /**
     * @dev Emitted when tax is collected.
     */
    event Tax(uint256 indexed tokenId, uint256 amount);

    /**
     * @dev Emitted when UBI is distributed.
     */
    event UBI(uint256 indexed tokenId, uint256 amount);

    /**
     * @dev Tax record of token.
     *
     * TODO: more efficient storage scheme, see: https://medium.com/@novablitz/storing-structs-is-costing-you-gas-774da988895e
     */
    struct TaxRecord {
        uint256 price;
        uint256 lastTaxCollection;
        uint256 ubiWithdrawn;
    }

    /**
     * @dev Mapping from token id to tax record.
     */
    mapping(uint256 => TaxRecord) public taxRecord;

    /**
     * @dev Tax rate in percentage.
     */
    uint256 public taxRate;

    /**
     * @dev Share for community treasury in percentage.
     */
    uint256 public treasuryShare;

    uint256 public accumulatedUBI;

    uint256 public totalSupply;

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
        string memory propertyName_,
        string memory propertySymbol_,
        address currencyAddress_,
        uint256 taxRate_,
        uint256 totalSupply_
    ) {
        // initialize Property contract with current contract as market
        property = new Property(propertyName_, propertySymbol_, address(this), totalSupply_);

        // initialize currency contract
        currency = ERC20(currencyAddress_);

        // TODO: tax rate setter
        totalSupply = totalSupply_;
        taxRate = taxRate_;
    }

    /**
     * @dev Set the current price of an Harberger property with token id.
     *
     * Emits a {Price} event.
     */
    function setPrice(uint256 tokenId_, uint256 price_) external {
        require(property.ownerOf(tokenId_) == msg.sender, "Sender does not own property");

        _setPrice(tokenId_, price_);
    }

    /**
     * @dev Returns the current price of an Harberger property with token id.
     */
    function getPrice(uint256 tokenId_) external view returns (uint256 price) {
        return taxRecord[tokenId_].price;
    }

    /**
     * @dev Purchase property with bid higher than current price. Clear tax for owner before transfer.
     * TODO: check security implications
     */
    function bid(uint256 tokenId_, uint256 price_) external {
        // TODO: mint token if not already exists

        require(price_ >= this.getPrice(tokenId_), "Price too low");

        // collect tax
        bool success = this.collectTax(tokenId_);

        if (success) {
            // successfully clear tax
            currency.transferFrom(msg.sender, property.ownerOf(tokenId_), price_);
            property.safeTransferByMarket(property.ownerOf(tokenId_), msg.sender, tokenId_);
        } else {
            // if failed, mint to current bidder
            property.mint(msg.sender, tokenId_);
        }
    }

    /**
     * @dev Collect outstanding property tax for a given token, put token on tax sale if obligation not met.
     *
     * Emits a {Tax} event and a {Price} event (when properties are put on tax sale).
     */
    function collectTax(uint256 _tokenId) external returns (bool) {
        uint256 price = this.getPrice(_tokenId);
        if (price > 0) {
            // TODO: time window for tax rate

            // calculate tax
            uint256 tax = (price * taxRate * (block.timestamp - taxRecord[_tokenId].lastTaxCollection)) / 100;

            // calculate collectable amount
            address taxpayer = property.ownerOf(_tokenId);
            uint256 allowance = currency.allowance(taxpayer, address(this));
            uint256 balance = currency.balanceOf(taxpayer);

            uint256 collectable = _min(allowance, balance);

            // collect tax or default
            if (tax < collectable) {
                // default
                currency.transferFrom(property.ownerOf(_tokenId), address(this), collectable);
                _default(_tokenId);
                return false;
            } else {
                // collect tax
                currency.transferFrom(property.ownerOf(_tokenId), address(this), tax);
                return true;
            }
        } else {
            // no tax for price 0
            return true;
        }
    }

    function withdrawUBI(uint256 _tokenId) external {
        uint256 ubi = (accumulatedUBI * (100 - treasuryShare)) / totalSupply - taxRecord[_tokenId].ubiWithdrawn;

        if (ubi > 0) {
            currency.transferFrom(address(this), property.ownerOf(_tokenId), ubi);
            emit UBI(_tokenId, ubi);
        }
    }

    function _default(uint256 tokenId_) internal {
        property.burn(tokenId_);
        _setPrice(tokenId_, 0);
    }

    function _setPrice(uint256 tokenId_, uint256 price_) internal {
        // update price in tax record
        taxRecord[tokenId_].price = price_;

        // emit events
        emit Price(tokenId_, price_);
    }

    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}
