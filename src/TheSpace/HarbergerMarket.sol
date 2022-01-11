//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Asset.sol";

/**
 * @dev Market place with Harberger tax, inherits from `IPixelCanvas`. Market creates one ERC721 contract as property, and attaches one ERC20 contract as currency.
 */
abstract contract HarbergerMarket {
  /**
   * @dev Emitted when a token changes price.
   */
  event Price(uint64 indexed tokenId, uint256 price);

  /**
   * @dev Emitted when tax is collected.
   */
  event Tax(address indexed from, uint256 amount);

  /**
   * @dev Emitted when tax is collected.
   */
  event Dividend(address indexed to, uint256 amount);

  /**
   * @dev Mapping from asset token id to price.
   */
  mapping(uint64 => uint256) public assetPrice;

  /**
   * @dev Mapping from owner addresses to timestamp of last tax collection.
   */
  mapping(address => uint256) public taxTime;

  /**
   * @dev Owner address list to iterate upon.
   */
  address[] public assetOwnerList;

  /**
   * @dev Total market capitalization
   */
  uint256 public marketCap;

  /**
   * @dev Tradable assets created by this contract.
   */
  Asset public asset;

  /**
   * @dev ERC20 token used as currency
   */
  ERC20 public currency;

  // TBD: restrict minting tokens outside of canvas?
  // uint64 public totalSupply = 20000000000;

  /**
   * @dev Tax rate in percentage.
   */
  uint8 public taxRate;

  /**
   * @dev Create Asset contract, setup attached currency contract, setup tax rate
   */
  constructor(
    string memory assetName_,
    string memory assetSymbol_,
    address currencyAddress_,
    uint8 taxRate_
  ) {
    // initialize Asset contract with current contract as market
    asset = new Asset(assetName_, assetSymbol_, address(this));

    // initialize currency contract
    currency = ERC20(currencyAddress_);

    // TBD: shall we allow changes of tax rate?
    taxRate = taxRate_;
  }

  // /**
  //  * @dev Set address for attached currency contract.
  //  *
  //  */
  // function setCurrencyAddress(address _currencyAddress) external {
  //   require(_currencyAddress != address(0), "Address cannot be null");

  //   currency = ERC20(_currencyAddress);
  // }

  /**
   * @dev Set the current price of an Harberger property with token id.
   *
   * Emits a {Price} event.
   */
  function setPrice(uint64 _tokenId, uint256 _price) external {
    require(asset.ownerOf(_tokenId) == msg.sender, "Sender does not own asset");

    // update asset price
    assetPrice[_tokenId] = _price;

    // update market price
    marketCap += _price;

    // emit events
    emit Price(_tokenId, _price);
  }

  /**
   * @dev Returns the current price of an Harberger property with token id.
   */
  function getPrice(uint64 tokenId) external view returns (uint256 price) {
    return assetPrice[tokenId];
  }

  /**
   * @dev Purchase property with bid higher than current price. Clear tax for owner before transfer.
   * TODO: check security implications
   */
  function bid(uint64 tokenId, uint256 price) external {
    // TODO: mint token if not already exists, assign resource if needed

    require(price >= this.getPrice(tokenId), "Price too low");

    // collect tax
    this.collectTax(asset.ownerOf(tokenId));

    // TODO: handle default scenario
    // transfer currency
    currency.transferFrom(msg.sender, asset.ownerOf(tokenId), price);

    // transfer asset
    asset.safeTransferByMarket(asset.ownerOf(tokenId), msg.sender, tokenId);
  }

  /**
   * @dev Collect outstanding property tax for a given address, put property on tax sale if obligation not met.
   *
   * Emits a {Tax} event and a {Price} event (when properties are put on tax sale).
   */
  function collectTax(address taxpayer) external {
    uint256 totalAssetValue = _getAssetValue(taxpayer);
    if (totalAssetValue > 0) {
      // address(this).balance
      currency.transferFrom(
        taxpayer,
        address(this),
        (totalAssetValue * taxRate) / 100
      );

      // TODO: default asset if owner does not have enough
      taxTime[taxpayer] = block.timestamp;
    }
  }

  /**
   * @dev Collect all outstanding property tax, put property on tax sale if obligation not met.
   *
   * Emits {Tax} events and {Price} events (when properties are put on tax sale).
   */
  function collectTaxForAll() external {
    // TODO: collect tax for all users with old enough tax timestamp, and reward caller
  }

  /**
   * @dev Payout all dividends from current balance.
   *
   * Emits {Dividend} events.
   */
  function distributeDividendForAll() external {
    // TODO: rewards caller, keep part as community pool
    for (uint64 i = 0; i < assetOwnerList.length; i++) {
      uint256 dividend = (_getAssetValue(assetOwnerList[i]) *
        currency.balanceOf(address(this))) / marketCap;

      // transfer dividend
      currency.transfer(assetOwnerList[i], dividend);

      // emit events
      emit Dividend(assetOwnerList[i], dividend);
    }
  }

  /**
   * @dev Get total asset value of a given address.
   */
  function _getAssetValue(address owner) internal view returns (uint256) {
    uint256 balance = asset.balanceOf(owner);
    uint256 totalAssetValue = 0;
    if (balance > 0) {
      for (uint256 i = 0; i < balance; i++) {
        uint256 tokenId = asset.tokenOfOwnerByIndex(owner, i);
        totalAssetValue += assetPrice[uint64(tokenId)];
      }
    }
    return totalAssetValue;
  }
}
