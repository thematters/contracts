## `IHarbergerMarket`



Market place with Harberger tax. Market creates one ERC721 contract as property, and attaches one ERC20 contract as currency.


## Functions
### `getPropertyContract() → address propertyContract` (external)



Get address for attached property contract. Property contract is a ERC721 contract deployed by market contract.

### `setCurrencyContract(address currencyContract)` (external)



Set address for attached currency contract.


### `getCurrencyContract() → address currencyContract` (external)



Get address for attached currency contract.

### `setPrice(uint256 tokenId, uint256 price)` (external)



Set the current price of an Harberger property with token id.

Emits a {Price} event.

### `getPrice(uint256 tokenId) → uint256 price` (external)



Returns the current price of an Harberger property with token id.

### `bid(uint256 tokenId, uint256 price)` (external)



Purchase property with bid higher than current price. Clear tax for owner before transfer.

### `collectTax(address taxpayer)` (external)



Collect outstanding property tax for a given address, put property on tax sale if obligation not met.

Emits a {Tax} event and a {Price} event (when properties are put on tax sale).

### `collectTaxForAll()` (external)



Collect all outstanding property tax, put property on tax sale if obligation not met.

Emits {Tax} events and {Price} events (when properties are put on tax sale).


## Events
### `Price(uint256 tokenId, uint256 price)`



Emitted when a token changes price.

### `Tax(address from, uint256 amount)`



Emitted when tax is collected.



