## `Snapper`

The data storage part of the whole `Snapper` app.

Logics like generating snapshot image / delta file and calling `takeSnapshot` are handled by the Lambda part.
`latestSnapshotInfo` is the only method clients should care about.

## Functions

### `constructor()` (public)

Create Snapper contract.

### `initRegion(uint256 regionId, uint256 initBlock_, string snapshotCid_)` (external)

Intialize the region before taking further snapshots.

Emits {Snapshot} event which used by Clients to draw initial picture.

### `takeSnapshot(uint256 regionId, uint256 lastSnapshotBlock_, uint256 targetSnapshotBlock_, string snapshotCid_, string deltaCid_)` (external)

Take a snapshot on the region.

Emits {Snapshot} and {Delta} events.

### `latestSnapshotInfo() → struct Snapper.SnapshotInfo` (external)

Get region 0 lastest snapshot info.

### `latestSnapshotInfo(uint256 regionId) → struct Snapper.SnapshotInfo` (external)

Get the lastest snapshot info by region.

## Events

### `Snapshot(uint256 regionId, uint256 block, string cid)`

New snapshot is taken.

For more information see https://gist.github.com/zxygentoo/6575a49ff89831cdd71598d49527278b

### `Delta(uint256 regionId, uint256 block, string cid)`

New delta is generated.

For more information see https://gist.github.com/zxygentoo/6575a49ff89831cdd71598d49527278b

### `SnapshotInfo`

uint256
block

string
cid
