//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Properties that are traded using Harberger tax.
 */
interface IHarbergerProperty is IERC721 {
  /**
   * @dev Emitted when an Harberger market contract is attached to the property.
   */
  event MarketContract(address indexed marketContract);

  /**
   * @dev Set address for attached market contract.
   *
   * Emits a {MarketContract} event.
   */
  function setMarketContract(address marketContract) external;

  /**
   * @dev Get address for attached market contract.
   */
  function getMarketContract() external view returns (address marketContract);

  /**
   * @dev Return owner address by index
   */
  function ownerByIndex(uint256 index) external view returns (address owner);

  /**
   * @dev Return property share by owner, unit with 1 / giga (1 ^ -9). Useful for purposes such as UBI (universal basic income).
   */
  function shareByOwner(address owner) external view returns (uint32 share);

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked. Allows market contract as operator.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from` or current market contract, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external override;

  /**
   * @dev Transfers `tokenId` token from `from` to `to`. Allows market contract as operator.
   *
   * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   * - If the caller is not `from` or current market contract, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external override;
}
