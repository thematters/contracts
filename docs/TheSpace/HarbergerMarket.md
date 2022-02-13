## `HarbergerMarket`



Market place with Harberger tax, inherits from `IPixelCanvas`. Market creates one ERC721 contract as property, and attaches one ERC20 contract as currency.


## Functions
### `constructor(string assetName_, string assetSymbol_, address currencyAddress_, uint8 taxRate_)` (internal)



Create Asset contract, setup attached currency contract, setup tax rate

### `setPrice(uint64 _tokenId, uint256 _price)` (external)



Set the current price of an Harberger property with token id.

Emits a {Price} event.

### `getPrice(uint64 tokenId) → uint256 price` (external)



Returns the current price of an Harberger property with token id.

### `bid(uint64 tokenId, uint256 price)` (external)



Purchase property with bid higher than current price. Clear tax for owner before transfer.
TODO: check security implications

### `collectTax(address taxpayer)` (external)



Collect outstanding property tax for a given address, put property on tax sale if obligation not met.

Emits a {Tax} event and a {Price} event (when properties are put on tax sale).

### `collectTaxForAll()` (external)



Collect all outstanding property tax, put property on tax sale if obligation not met.

Emits {Tax} events and {Price} events (when properties are put on tax sale).

### `distributeDividendForAll()` (external)



Payout all dividends from current balance.

Emits {Dividend} events.

### `_getAssetValue(address owner) → uint256` (internal)



Get total asset value of a given address.


## Events
### `Price(uint64 tokenId, uint256 price)`



Emitted when a token changes price.

### `Tax(address from, uint256 amount)`



Emitted when tax is collected.

### `Dividend(address to, uint256 amount)`



Emitted when tax is collected.



