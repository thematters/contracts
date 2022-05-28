// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title The `Snapper` contract.
 * @notice The data storage part of the whole `Snapper` app.
 * @dev Logics like generating snapshot image / delta file and calling `takeSnapshot` are handled by the Lambda part.
 * @dev `latestSnapshotInfo` is the only method clients should care about.
 */
contract Snapper is Ownable {
    /**
     * @notice Initialize intialized regions.
     * @param regionId The id of region which have its own snapshot.
     */
    error CannotBeReInitialized(uint256 regionId);

    /**
     * @notice `lastSnapshotBlock_` value is invaild.
     * @dev `lastSnapshotBlock_` must be equal to the region latest snapshot block.
     * @param regionId The region snapshotted on.
     * @param last The wrong `lastSnapshotBlock_` value.
     * @param latest The value `lastSnapshotBlock_` should be.
     */
    error InvalidLastSnapshotBlock(uint256 regionId, uint256 last, uint256 latest);

    /**
     * @notice `targetSnapshotBlock_` value is invaild.
     * @dev `targetSnapshotBlock_` must be greater than region latest snapshot block.
     * @param regionId The region snapshotted on.
     * @param target The wrong `targetSnapshotBlock_` value.
     * @param latest The value `targetSnapshotBlock_` should greater than.
     */
    error InvalidTargetSnapshotBlock(uint256 regionId, uint256 target, uint256 latest);

    /**
     * @notice New snapshot is taken.
     * @dev For more information see https://gist.github.com/zxygentoo/6575a49ff89831cdd71598d49527278b
     * @param regionId The map region snapshotted on.
     * @param block The block number snapshotted for The Space.
     * @param cid IPFS CID of the snapshot file.
     */
    event Snapshot(uint256 indexed regionId, uint256 indexed block, string cid);

    /**
     * @notice New delta is generated.
     * @dev For more information see https://gist.github.com/zxygentoo/6575a49ff89831cdd71598d49527278b
     * @param regionId The region snapshotted on.
     * @param block Delta end at this block number, inclusive
     * @param cid IPFS CID of the delta file.
     */
    event Delta(uint256 indexed regionId, uint256 indexed block, string cid);

    /**
     * @notice Snapshot info.
     */
    struct SnapshotInfo {
        uint256 block;
        string cid;
    }

    /**
     * @dev Store each regions' latest snapshot info.
     */
    mapping(uint256 => SnapshotInfo) private _latestSnapshots;

    /**
     * @notice Create Snapper contract.
     */
    constructor() {}

    /**
     * @notice Intialize the region before taking further snapshots.
     * @dev Emits {Snapshot} event which used by Clients to draw initial picture.
     * @param regionId The region to intialize.
     * @param initBlock_ The Contract Creation block number of The Space contract.
     * @param snapshotCid_ The initial pixels picture IPFS CID of The Space.
     */
    function initRegion(
        uint256 regionId,
        uint256 initBlock_,
        string calldata snapshotCid_
    ) external onlyOwner {
        if (_latestSnapshots[regionId].block != 0) revert CannotBeReInitialized(regionId);

        _latestSnapshots[regionId].block = initBlock_;
        _latestSnapshots[regionId].cid = snapshotCid_;

        emit Snapshot(regionId, initBlock_, snapshotCid_);
    }

    /**
     * @notice Take a snapshot on the region.
     * @dev Emits {Snapshot} and {Delta} events.
     * @param regionId The region snapshotted on.
     * @param lastSnapshotBlock_ Last block number snapshotted for The Space. use to validate precondition.
     * @param targetSnapshotBlock_ The block number snapshotted for The Space this time.
     */
    function takeSnapshot(
        uint256 regionId,
        uint256 lastSnapshotBlock_,
        uint256 targetSnapshotBlock_,
        string calldata snapshotCid_,
        string calldata deltaCid_
    ) external onlyOwner {
        uint256 _latestSnapshotBlock = _latestSnapshots[regionId].block;
        if (lastSnapshotBlock_ != _latestSnapshotBlock || lastSnapshotBlock_ == 0)
            revert InvalidLastSnapshotBlock(regionId, lastSnapshotBlock_, _latestSnapshotBlock);

        if (targetSnapshotBlock_ <= _latestSnapshotBlock)
            revert InvalidTargetSnapshotBlock(regionId, targetSnapshotBlock_, _latestSnapshotBlock);

        _latestSnapshots[regionId].block = targetSnapshotBlock_;
        _latestSnapshots[regionId].cid = snapshotCid_;

        emit Snapshot(regionId, targetSnapshotBlock_, snapshotCid_);
        emit Delta(regionId, targetSnapshotBlock_, deltaCid_);
    }

    /**
     * @notice Get region 0 lastest snapshot info.
     */
    function latestSnapshotInfo() external view returns (SnapshotInfo memory) {
        return _latestSnapshots[0];
    }

    /**
     * @notice Get the lastest snapshot info by region.
     * @param regionId ID of the region to query.
     */
    function latestSnapshotInfo(uint256 regionId) external view returns (SnapshotInfo memory) {
        return _latestSnapshots[regionId];
    }
}
