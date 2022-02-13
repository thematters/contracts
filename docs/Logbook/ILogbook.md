## `ILogbook`

The interface is inherited from IERC721 (for logbook as NFT) and IRoyalty (for royalty)

## Functions

### `setTitle(uint256 tokenId_, string title_)` (external)

Set logbook title

Emits a {SetTitle} event

### `setDescription(uint256 tokenId_, string description_)` (external)

Set logbook description

Emits a {SetDescription} event

### `setForkPrice(uint256 tokenId_, uint256 amount_)` (external)

Set logbook fork price

Emits a {SetForkPrice} event

### `multicall(bytes[] data) → bytes[] results` (external)

Batch calling methods of this contract

### `publish(uint256 tokenId_, string content_)` (external)

Publish a new log in a logbook

Emits a {Publish} event

### `fork(uint256 tokenId_, bytes32 contentHash_)` (external)

Pay to fork a logbook

Emits {Fork} and {Pay} events

### `donate(uint256 tokenId_)` (external)

Donate to a logbook

Emits {Donate} and {Pay} events

### `setRoyaltyBPSLogbookOwner(uint128 bps_)` (external)

Set royalty basis points of logbook owner

### `setRoyaltyBPSCommission(uint128 bps_)` (external)

Set royalty basis points of contract

## Events

### `SetTitle(uint256 tokenId, string title)`

Emitted when logbook title was set

### `SetDescription(uint256 tokenId, string description)`

Emitted when logbook description was set

### `SetForkPrice(uint256 tokenId, uint256 amount)`

Emitted when logbook fork price was set

### `Publish(uint256 tokenId, address author, bytes32 contentHash, string content)`

Emitted when logbook owner publish a new log

### `Fork(uint256 tokenId, uint256 newTokenId, address owner, bytes32 contentHash, uint256 amount)`

Emitted when a logbook was forked

### `Donate(uint256 tokenId, address donor, uint256 amount)`

Emitted when a logbook received a donation
