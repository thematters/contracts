## `Property`

Harberger property, constantly in auction by allowing market contract to transfer token.

## Functions

### `constructor(string name_, string symbol_, address marketAddress_, uint256 totalSupply_)` (public)

Initializes the contract by setting a `name` and a `symbol` to the token collection.

### `safeTransferByMarket(address from_, address to_, uint256 tokenId_)` (public)

Transfer token by market contract.

### `burn(uint256 tokenId_)` (public)

Burn token by market contract.

### `mint(address to_, uint256 tokenId_)` (public)

Mint token by market contract.

### `setTokenURI(uint256 tokenId_, string tokenURI_)` (internal)

Sets `_tokenURI` as the tokenURI of `tokenId`.

Requirements:

- `tokenId` must exist.

### `tokenURI(uint256 tokenId) → string` (public)

Return token URI
