## `ILogbook`

The interface is inherited from IERC721 (for logbook as NFT) and IRoyalty (for royalty)

## Functions

### `setTitle(uint256 tokenId_, string title_)` (external)

Set logbook title

Access Control: logbook owner
Emits a {SetTitle} event

### `setDescription(uint256 tokenId_, string description_)` (external)

Set logbook description

Access Control: logbook owner
Emits a {SetDescription} event

### `setForkPrice(uint256 tokenId_, uint256 amount_)` (external)

Set logbook fork price

Access Control: logbook owner
Emits a {SetForkPrice} event

### `multicall(bytes[] data) → bytes[] results` (external)

Batch calling methods of this contract

### `publish(uint256 tokenId_, string content_)` (external)

Publish a new log in a logbook

Access Control: logbook owner
Emits a {Publish} event

### `fork(uint256 tokenId_, uint32 endAt_) → uint256 tokenId` (external)

Pay to fork a logbook

Emits {Fork} and {Pay} events

### `forkWithCommission(uint256 tokenId_, uint32 endAt_, address commission_, uint256 commissionBPS_) → uint256 tokenId` (external)

Pay to fork a logbook with commission

Emits {Fork} and {Pay} events

### `donate(uint256 tokenId_)` (external)

Donate to a logbook

Emits {Donate} and {Pay} events

### `donateWithCommission(uint256 tokenId_, address commission_, uint256 commissionBPS_)` (external)

Donate to a logbook with commission

Emits {Donate} and {Pay} events

### `getLogbook(uint256 tokenId_) → struct ILogbook.Book book` (external)

Get a logbook

### `getLogs(uint256 tokenId_) → bytes32[] contentHashes, address[] authors` (external)

Get a logbook's logs

### `claim(address to_, uint256 logrsId_)` (external)

Claim a logbook with a Traveloggers token

Access Control: contract deployer

### `publicSaleMint() → uint256 tokenId` (external)

Mint a logbook

### `setPublicSalePrice(uint256 price_)` (external)

Set public sale

Access Control: contract deployer

### `turnOnPublicSale()` (external)

Turn on public sale

Access Control: contract deployer

### `turnOffPublicSale()` (external)

Turn off public sale

Access Control: contract deployer

## Events

### `SetTitle(uint256 tokenId, string title)`

Emitted when logbook title was set

### `SetDescription(uint256 tokenId, string description)`

Emitted when logbook description was set

### `SetForkPrice(uint256 tokenId, uint256 amount)`

Emitted when logbook fork price was set

### `Content(address author, bytes32 contentHash, string content)`

Emitted when a new log was created

### `Publish(uint256 tokenId, bytes32 contentHash)`

Emitted when logbook owner publish a new log

### `Fork(uint256 tokenId, uint256 newTokenId, address owner, uint32 end, uint256 amount)`

Emitted when a logbook was forked

### `Donate(uint256 tokenId, address donor, uint256 amount)`

Emitted when a logbook received a donation

### `Log`

address
author

uint256
tokenId

### `Book`

uint32
endAt

uint32
logCount

uint32
transferCount

uint160
createdAt

uint256
parent

uint256
forkPrice

bytes32[]
contentHashes

### `SplitRoyaltyFees`

uint256
commission

uint256
logbookOwner

uint256
perLogAuthor
