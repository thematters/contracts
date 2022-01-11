//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Asset is ERC721Enumerable {
  /**
   * @dev Emitted when the tokenization of pixels is updated.
   */
  event Tokenize(uint64 indexed tokenId, uint64[] pixelIds);

  /**
   * @dev Map asset id to resource ids.
   */
  mapping(uint64 => uint64[]) public assetResourcesMap;

  /**
   * @dev Map resource id to asset id
   */
  mapping(uint64 => uint64) public resourceAssetMap;

  // Optional mapping for token URIs
  mapping(uint256 => string) private _tokenURIs;

  /**
   * @dev Address of market contract, allowed to move assets via safeTransferByMarket
   */
  address public marketAddress;

  /**
   * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
   */
  constructor(
    string memory name_,
    string memory symbol_,
    address marketAddress_
  ) ERC721(name_, symbol_) {
    marketAddress = marketAddress_;
  }

  /**
   * @dev Transfer assets by market contract.
   */
  function safeTransferByMarket(
    address from,
    address to,
    uint256 tokenId
  ) public {
    require(msg.sender == marketAddress, "Only market contract can call");
    _safeTransfer(from, to, tokenId, "");
  }

  /**
   * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function setTokenURI(uint256 tokenId, string memory _tokenURI)
    internal
    virtual
  {
    require(_exists(tokenId), "URI set of nonexistent token");
    _tokenURIs[tokenId] = _tokenURI;
  }

  /**
   * @dev Return token URI
   */
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), "URI query for nonexistent token");
    string memory _tokenURI = _tokenURIs[tokenId];

    return _tokenURI;
  }

  /**
   * @dev Combine pixels from multiple tokens into a new token. Old tokens are burnt or pointed to an empty array of pixels.
   *
   * Requirements:
   *
   * - For all tokens, the caller needs to own or approved to move it by either {approve} or {setApprovalForAll}.
   * - Corresponding pixels need to form a connected space.
   *
   * Emits a {Tokenize} event.
   */
  function groupTokens(uint64[] calldata tokenIds) external {
    // TODO
  }

  /**
   * @dev Ungroup pixels from a token into multiple tokens, where new token ids equal to pixel ids. New tokens are assigned to the same address as the original owner.
   *
   * Emits {Tokenize} events.
   */
  function ungroupToken() external returns (uint64[] memory tokenIds) {
    // TODO
  }
}
