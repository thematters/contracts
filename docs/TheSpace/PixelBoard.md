## `PixelBoard`






## Functions
### `constructor(string _assetName, string _assetSymbol, address _currencyAddress, uint8 _taxRate)` (internal)





### `setColors(uint64[] pixelIds, uint8[] colors)` (external)



Set colors in batch for an array of pixels.

Emits {Color} events.


## Events
### `Color(uint64 pixelId, uint8 color)`



Emitted when the color of a pixel is updated.
TBD: use uint8 for color encoding?



