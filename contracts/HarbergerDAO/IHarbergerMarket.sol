//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @dev interface of a market using Harberger tax and UBI.
 */
interface IHarbergerMarket {
  /**
   * @dev Emitted when an ERC721 Harberger property contract is attached to the market place.
   */
  event PropertyContract(address indexed propertyContract);

  /**
   * @dev Emitted when an ERC20 currency contract is attached to the market place.
   */
  event CurrencyContract(address indexed currencyContract);

  /**
   * @dev Emitted when a token changes price.
   */
  event Price(uint256 indexed tokenId, uint256 price);

  /**
   * @dev Emitted when tax is collected.
   */
  event Tax(address indexed from, uint256 amount);

  /**
   * @dev Emitted when UBI is distributed
   */
  event UBI(address indexed to, uint256 amount);

  /**
   * @dev Set address for attached property contract.
   *
   * Emits a {PropertyContract} event.
   */
  function setPropertyContract(address propertyContract) external;

  /**
   * @dev Get address for attached property contract.
   */
  function getPropertyContract()
    external
    view
    returns (address propertyContract);

  /**
   * @dev Set address for attached currency contract.
   *
   * Emits a {CurrencyContract} event.
   */
  function setCurrencyContract(address currencyContract) external;

  /**
   * @dev Get address for attached currency contract.
   */
  function getCurrencyContract()
    external
    view
    returns (address currencyContract);

  /**
   * @dev Set the current price of an Harberger property with token id.
   *
   * Emits a {Price} event.
   */
  function setPrice(uint256 tokenId, uint256 price) external;

  /**
   * @dev Returns the current price of an Harberger property with token id.
   */
  function getPrice(uint256 tokenId) external view returns (uint256 price);

  /**
   * @dev Purchase property with bid higher than current price. Clear tax for owner before transfer.
   */
  function bid(uint256 tokenId, uint256 price) external;

  /**
   * @dev Collect all outstanding property tax, put property on tax sale if obligation not met.
   *
   * Emits {Tax} events and {Price} events (when properties are put on tax sale).
   */
  function collectTaxForAll() external;

  /**
   * @dev Distribute all outstanding universal basic income based on Harberger property.
   *
   * Emits {UBI} events.
   */
  function distributeUBI() external;
}
