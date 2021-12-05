## `ILand`



ERC721 contract representing land. Allow owner to set token uri for each token, and emits an event to record the uri as token content.


## Functions
### `setTokenURI(uint256 tokenId, string uri)` (external)



Set the Uniform Resource Identifier (URI) for `tokenId` token.

Emits a {TokenContent} event.

### `tokenURI(uint256 tokenId) → string` (external)



Returns the Uniform Resource Identifier (URI) for `tokenId` token.


## Events
### `TokenContent(address author, uint256 tokenId, string content)`







