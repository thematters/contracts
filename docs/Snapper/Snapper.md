## `Snapper`

## Functions

### `constructor(uint256 theSpaceCreationBlock_, string snapshotCid_)` (public)

create Snapper contract with initial snapshot.

Emits {Snapshot} event.

### `takeSnapshot(uint256 lastSnapshotBlock_, uint256 snapshotBlock_, string snapshotCid_, string deltaCid_)` (external)

Emits {Snapshot} and {Delta} events.

### `latestSnapshotInfo() → uint256 latestSnapshotBlock, string latestSnapshotCid` (external)

get the lastest snapshot info.

## Events

### `Snapshot(uint256 block, string cid)`

snapshot info

### `Delta(uint256 block, string cid)`

delta info
