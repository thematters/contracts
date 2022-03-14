//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @dev Harberger property, constantly in auction by allowing market contract to transfer token.
 */
contract Property is ERC721Enumerable {
    error TokenNotExists();
    error Unauthorized();
    error InvalidTokenId(uint256 min, uint256 max);

    // mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev Address of market contract, allowed to move token via safeTransferByMarket
     */
    address public market;

    /**
     * @dev total supply of token
     */
    uint256 private _totalSupply;

    modifier onlyMarket() {
        if (msg.sender != market) revert Unauthorized();
        _;
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(
        string memory name,
        string memory symbol,
        address marketAddress,
        uint256 totalSupply
    ) ERC721(name, symbol) {
        market = marketAddress;
        _totalSupply = totalSupply;
    }

    /**
     * @dev Transfer token by market contract.
     */
    function safeTransferByMarket(
        address from_,
        address to,
        uint256 tokenId
    ) public onlyMarket {
        _safeTransfer(from_, to, tokenId, "");
    }

    /**
     * @dev Burn token by market contract.
     */
    function burn(uint256 tokenId) public onlyMarket {
        _burn(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function isApprovedOrOwner(address spender, uint256 tokenId) public view returns (bool) {
        return _isApprovedOrOwner(spender, tokenId);
    }

    /**
     * @dev Mint token by market contract.
     */
    function mint(address to, uint256 tokenId) public onlyMarket {
        if (tokenId > _totalSupply || tokenId < 1) revert InvalidTokenId(1, _totalSupply);

        _safeMint(to, tokenId);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev Sets `tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function setTokenURI(uint256 tokenId, string memory uri) internal virtual {
        if (!_exists(tokenId)) revert TokenNotExists();
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert Unauthorized();

        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Return token URI
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert TokenNotExists();

        string memory _tokenURI = _tokenURIs[tokenId];
        return _tokenURI;
    }
}
