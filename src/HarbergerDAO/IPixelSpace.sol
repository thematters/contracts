//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IHarbergerProperty.sol";

interface IPixelSpace is IHarbergerProperty {
  /**
   * @dev Emitted when a pixels included in a token is updated.
   */
  event TokenPixels(uint256 indexed tokenId, uint256[] pixelIds);

  /**
   * @dev Emitted when the color of a pixel is updated.
   */
  event PixelColor(uint256 indexed pixelId, string color);

  /**
   * @dev Emitted when the content of a token is updated.
   */
  event TokenContent(uint256 indexed tokenId, string content);

  /**
   * @dev Combine tokens into a new token inheriting all pixels. New token id is the smallest among input tokens, while other tokens are burnt.
   *
   * Emits a {TokenPixels} event.
   */
  function groupTokens(uint256[] calldata tokenIds) external;

  /**
   * @dev Ungroup pixels from a token into multiple tokens, where new token ids equal to pixel ids. New tokens are assigned to the same address as the original owner.
   *
   * Emits {TokenPixels} events.
   */
  function ungroupToken() external returns (uint256[] memory tokenIds);

  /**
   * @dev Set colors in batch for an array of pixels.
   *
   * Emits {PixelColor} events.
   */
  function setColors(uint256[] calldata pixelIds, string[] calldata colors)
    external;

  /**
   * @dev Set colors in batch for an array of pixels.
   */
  function getTokenId(uint256 pixelId) external view returns (uint256 tokenId);

  /**
   * @dev Set content for a token.
   *
   * Emits a {TokenContent} event.
   */
  function setContent(uint256 tokenId) external;
}
