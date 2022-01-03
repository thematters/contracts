//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev ERC721 contract representing land, inherits from openzeppelin ERC721. Allow owner to set token uri for each token, and emits an event to record the uri as token content.
 */
interface ILand is IERC721 {
  event TokenContent(
    address indexed author,
    uint256 indexed tokenId,
    string content
  );

  /**
   * @dev Set the Uniform Resource Identifier (URI) for `tokenId` token.
   *
   * Emits a {TokenContent} event.
   */
  function setTokenURI(uint256 tokenId, string calldata uri) external;

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(uint256 tokenId) external view returns (string memory);
}
