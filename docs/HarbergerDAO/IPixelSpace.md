## `IPixelSpace`






### `groupTokens(uint256[] tokenIds)` (external)



Combine tokens into a new token inheriting all pixels. New token id is the smallest among input tokens, while other tokens are burnt.

Emits a {TokenPixels} event.

### `ungroupToken() → uint256[] tokenIds` (external)



Ungroup pixels from a token into multiple tokens, where new token ids equal to pixel ids. New tokens are assigned to the same address as the original owner.

Emits {TokenPixels} events.

### `setColors(uint256[] pixelIds, string[] colors)` (external)



Set colors in batch for an array of pixels.

Emits {PixelColor} events.

### `getTokenId(uint256 pixelId) → uint256 tokenId` (external)



Set colors in batch for an array of pixels.

### `setContent(uint256 tokenId)` (external)



Set content for a token.

Emits a {TokenContent} event.


### `TokenPixels(uint256 tokenId, uint256[] pixelIds)`



Emitted when a pixels included in a token is updated.

### `PixelColor(uint256 pixelId, string color)`



Emitted when the color of a pixel is updated.

### `TokenContent(uint256 tokenId, string content)`



Emitted when the content of a token is updated.



