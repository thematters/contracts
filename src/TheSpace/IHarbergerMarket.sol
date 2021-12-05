//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IPixelCanvas.sol";

/**
 * @dev Market place with Harberger tax. Market creates one ERC721 contract as property, and attaches one ERC20 contract as currency.
 */
interface IHarbergerMarket is IPixelCanvas {
  /**
   * @dev Emitted when a token changes price.
   */
  event Price(uint256 indexed tokenId, uint256 price);

  /**
   * @dev Emitted when tax is collected.
   */
  event Tax(address indexed from, uint256 amount);

  /**
   * @dev Get address for attached property contract. Property contract is a ERC721 contract deployed by market contract.
   */
  function getPropertyContract()
    external
    view
    returns (address propertyContract);

  /**
   * @dev Set address for attached currency contract.
   *
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
   * @dev Collect outstanding property tax for a given address, put property on tax sale if obligation not met.
   *
   * Emits a {Tax} event and a {Price} event (when properties are put on tax sale).
   */
  function collectTax(address taxpayer) external;

  /**
   * @dev Collect all outstanding property tax, put property on tax sale if obligation not met.
   *
   * Emits {Tax} events and {Price} events (when properties are put on tax sale).
   */
  function collectTaxForAll() external;
}
