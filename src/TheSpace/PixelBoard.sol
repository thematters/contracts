//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./HarbergerMarket.sol";

abstract contract PixelBoard is HarbergerMarket {
  /**
   * @dev Emitted when the color of a pixel is updated.
   * TBD: use uint8 for color encoding?
   */
  event Color(uint64 indexed pixelId, uint8 color);

  constructor(
    string memory _assetName,
    string memory _assetSymbol,
    address _currencyAddress,
    uint8 _taxRate
  ) HarbergerMarket(_assetName, _assetSymbol, _currencyAddress, _taxRate) {}

  /**
   * @dev Set colors in batch for an array of pixels.
   *
   * Emits {Color} events.
   */
  function setColors(uint64[] calldata pixelIds, uint8[] calldata colors)
    external
  {
    // TBD: upper bounds for batch update
    require(pixelIds.length < 500, "Batch size too big.");
    require(pixelIds.length == colors.length, "Lengths do not match.");

    // TBD: do we revert if pixels are partially owned?
    for (uint256 i = 0; i < pixelIds.length; i++) {
      uint64 assetId = asset.resourceAssetMap(pixelIds[i]);
      address owner = asset.ownerOf(assetId);
      require(owner == msg.sender, "Pixel not owned by caller.");
      emit Color(pixelIds[i], colors[i]);
    }
  }
}
