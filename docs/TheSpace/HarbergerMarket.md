## `HarbergerMarket`

Market place with Harberger tax, inherits from `IPixelCanvas`. Market creates one ERC721 contract as property, and attaches one ERC20 contract as currency.

## Functions

### `constructor(string propertyName_, string propertySymbol_, address currencyAddress_, uint256 taxRate_, uint256 totalSupply_)` (internal)

Create Property contract, setup attached currency contract, setup tax rate

### `setPrice(uint256 tokenId_, uint256 price_)` (external)

Set the current price of an Harberger property with token id.

Emits a {Price} event.

### `getPrice(uint256 tokenId_) → uint256 price` (external)

Returns the current price of an Harberger property with token id.

### `bid(uint256 tokenId_, uint256 price_)` (external)

Purchase property with bid higher than current price. Clear tax for owner before transfer.
TODO: check security implications

### `collectTax(uint256 _tokenId) → bool` (external)

Collect outstanding property tax for a given token, put token on tax sale if obligation not met.

Emits a {Tax} event and a {Price} event (when properties are put on tax sale).

### `withdrawUBI(uint256 _tokenId)` (external)

### `_default(uint256 tokenId_)` (internal)

### `_setPrice(uint256 tokenId_, uint256 price_)` (internal)

## Events

### `Price(uint256 tokenId, uint256 price)`

Emitted when a token changes price.

### `Tax(uint256 tokenId, uint256 amount)`

Emitted when tax is collected.

### `UBI(uint256 tokenId, uint256 amount)`

Emitted when UBI is distributed.

### `TaxRecord`

uint256
price

uint256
lastTaxCollection

uint256
ubiWithdrawn
