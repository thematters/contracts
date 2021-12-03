## `IHarbergerMarket`



Market with Harberger tax and UBI. Market attaches to one property contract that implements HarbergerProperty and one currency contract that implements ERC20.


## Functions
### `setPropertyContract(address propertyContract)` (external)



Set address for attached property contract.

Emits a {PropertyContract} event.

### `getPropertyContract() → address propertyContract` (external)



Get address for attached property contract.

### `setCurrencyContract(address currencyContract)` (external)



Set address for attached currency contract.

Emits a {CurrencyContract} event.

### `getCurrencyContract() → address currencyContract` (external)



Get address for attached currency contract.

### `setPrice(uint256 tokenId, uint256 price)` (external)



Set the current price of an Harberger property with token id.

Emits a {Price} event.

### `getPrice(uint256 tokenId) → uint256 price` (external)



Returns the current price of an Harberger property with token id.

### `bid(uint256 tokenId, uint256 price)` (external)



Purchase property with bid higher than current price. Clear tax for owner before transfer.

### `collectTaxForAll()` (external)



Collect all outstanding property tax, put property on tax sale if obligation not met.

Emits {Tax} events and {Price} events (when properties are put on tax sale).

### `distributeUBI()` (external)



Distribute all outstanding universal basic income based on Harberger property.

Emits {UBI} events.


## Events
### `PropertyContract(address propertyContract)`



Emitted when an ERC721 Harberger property contract is attached to the market place.

### `CurrencyContract(address currencyContract)`



Emitted when an ERC20 currency contract is attached to the market place.

### `Price(uint256 tokenId, uint256 price)`



Emitted when a token changes price.

### `Tax(address from, uint256 amount)`



Emitted when tax is collected.

### `UBI(address to, uint256 amount)`



Emitted when UBI is distributed



