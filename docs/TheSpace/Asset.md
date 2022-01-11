## `Asset`






## Functions
### `constructor(string name_, string symbol_, address marketAddress_)` (public)



Initializes the contract by setting a `name` and a `symbol` to the token collection.

### `safeTransferByMarket(address from, address to, uint256 tokenId)` (public)



Transfer assets by market contract.

### `setTokenURI(uint256 tokenId, string _tokenURI)` (internal)



Sets `_tokenURI` as the tokenURI of `tokenId`.

Requirements:

- `tokenId` must exist.

### `tokenURI(uint256 tokenId) → string` (public)



Return token URI

### `groupTokens(uint64[] tokenIds)` (external)



Combine pixels from multiple tokens into a new token. Old tokens are burnt or pointed to an empty array of pixels.

Requirements:

- For all tokens, the caller needs to own or approved to move it by either {approve} or {setApprovalForAll}.
- Corresponding pixels need to form a connected space.

Emits a {Tokenize} event.

### `ungroupToken() → uint64[] tokenIds` (external)



Ungroup pixels from a token into multiple tokens, where new token ids equal to pixel ids. New tokens are assigned to the same address as the original owner.

Emits {Tokenize} events.


## Events
### `Tokenize(uint64 tokenId, uint64[] pixelIds)`



Emitted when the tokenization of pixels is updated.



