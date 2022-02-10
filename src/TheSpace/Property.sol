//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @dev Harberger property, constantly in auction by allowing market contract to transfer token.
 */
contract Property is ERC721Enumerable {
    // mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev Address of market contract, allowed to move token via safeTransferByMarket
     */
    address public marketAddress;

    /**
     * @dev total supply of token
     */
    uint256 private _totalSupply;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address marketAddress_,
        uint256 totalSupply_
    ) ERC721(name_, symbol_) {
        marketAddress = marketAddress_;
        _totalSupply = totalSupply_;
    }

    /**
     * @dev Transfer token by market contract.
     */
    function safeTransferByMarket(
        address from_,
        address to_,
        uint256 tokenId_
    ) public {
        require(msg.sender == marketAddress, "Only market contract can call");
        _safeTransfer(from_, to_, tokenId_, "");
    }

    /**
     * @dev Burn token by market contract.
     */
    function burn(uint256 tokenId_) public {
        require(msg.sender == marketAddress, "Only market contract can call");
        _burn(tokenId_);
    }

    /**
     * @dev Mint token by market contract.
     */
    function mint(address to_, uint256 tokenId_) public {
        require(msg.sender == marketAddress, "Only market contract can call");
        _safeMint(to_, tokenId_);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function setTokenURI(uint256 tokenId_, string memory tokenURI_)
        internal
        virtual
    {
        require(_exists(tokenId_), "URI set of nonexistent token");
        require(msg.sender == this.ownerOf(tokenId_), "Only owner can set URI");
        _tokenURIs[tokenId_] = tokenURI_;
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
}
