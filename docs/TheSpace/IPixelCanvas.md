## `IPixelCanvas`



Pixel land where uses can tokenize pixels, trade tokens, and color pixels.


## Functions
### `groupTokens(uint256[] tokenIds)` (external)



Combine pixels from multiple tokens into a new token. Old tokens are burnt or pointed to an empty array of pixels.

Requirements:

- For all tokens, the caller needs to own or approved to move it by either {approve} or {setApprovalForAll}.
- Corresponding pixels need to form a connected space.

Emits a {Tokenized} event.


### `ungroupToken() → uint256[] tokenIds` (external)



Ungroup pixels from a token into multiple tokens, where new token ids equal to pixel ids. New tokens are assigned to the same address as the original owner.

Emits {TokenPixels} events.

### `setColors(uint256[] pixelIds, string[] colors)` (external)



Set colors in batch for an array of pixels.

Emits {PixelColor} events.

### `pixelToToken(uint256 pixelId) → uint256 tokenId` (external)



Get tokenId from pixelId

### `tokenToPixels(uint256 tokenId) → uint256[] pixelIds` (external)



Get pixelIds from tokenId


## Events
### `Tokenized(uint256 tokenId, uint256[] pixelIds)`



Emitted when the tokenization of pixels is updated.

### `Colored(uint256 pixelId, string color)`



Emitted when the color of a pixel is updated.



