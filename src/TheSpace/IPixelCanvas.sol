//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IHarbergerMarket.sol";

/**
 * @dev Pixel land where uses can tokenize pixels, trade tokens, and color pixels.
 */
interface IPixelCanvas {
  /**
   * @dev Emitted when the tokenization of pixels is updated.
   */
  event Tokenized(uint256 indexed tokenId, uint256[] pixelIds);

  /**
   * @dev Emitted when the color of a pixel is updated.
   */
  event Colored(uint256 indexed pixelId, string color);

  /**
   * @dev Combine pixels from multiple tokens into a new token. Old tokens are burnt or pointed to an empty array of pixels.
   *
   * Requirements:
   *
   * - For all tokens, the caller needs to own or approved to move it by either {approve} or {setApprovalForAll}.
   * - Corresponding pixels need to form a connected space.
   *
   * Emits a {Tokenized} event.
   *
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
   * @dev Get tokenId from pixelId
   */
  function pixelToToken(uint256 pixelId)
    external
    view
    returns (uint256 tokenId);

  /**
   * @dev Get pixelIds from tokenId
   */
  function tokenToPixels(uint256 tokenId)
    external
    view
    returns (uint256[] memory pixelIds);
}
