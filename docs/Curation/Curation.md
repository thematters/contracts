## `Curation`

## Functions

### `supportsInterface(bytes4 interfaceId_) → bool` (external)

See {IERC165-supportsInterface}.

### `curate(address to_, contract IERC20 token_, uint256 amount_, string uri_)` (public)

Curate content by ERC-20 token donation.

Emits: {Curation} event.
Throws: {ZeroAddress}, {ZeroAmount}, {InvalidURI} or {SelfCuration} error.

### `curate(address to_, string uri_)` (public)

Curate content by ERC-20 token donation.

Emits: {Curation} event.
Throws: {ZeroAddress}, {ZeroAmount}, {InvalidURI} or {SelfCuration} error.
