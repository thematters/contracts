## `ICuration`

Curation is the initial version for on-chain content curation.
It's permissionless, any address (curator) can send native or ERC-20 tokens to content creator's address to curate the specific content.

This is a stateless contract, it only emits events and no storage access.

## Functions

### `curate(address to_, contract IERC20 token_, uint256 amount_, string uri_)` (external)

Curate content by ERC-20 token donation.

Emits: {Curation} event.
Throws: {ZeroAddress}, {ZeroAmount}, {InvalidURI} or {SelfCuration} error.

### `curate(address to_, string uri_)` (external)

Curate content by native token donation.

Emits: {Curation} event.
Throws: {ZeroAddress}, {ZeroAmount}, {InvalidURI}, {TransferFailed} or {SelfCuration} error.

## Events

### `Curation(address from, address to, string uri, contract IERC20 token, uint256 amount)`

Content curation with ERC-20 token.

### `Curation(address from, address to, string uri, uint256 amount)`

Content curation with native token.
