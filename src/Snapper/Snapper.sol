// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Snapper is Ownable {
    /**
     * @notice snapshot info
     * @param block the block number the snapshot of.
     * @param cid IPFS CID of this snapshot file.
     */
    event Snapshot(uint256 indexed block, string cid);

    /**
     * @notice delta info
     * @param block this delta end at this block, inclusive
     * @param cid IPFS CID for this delta file.
     */
    event Delta(uint256 indexed block, string cid);

    /**
     * @dev last snapshot toBlock num.
     */
    uint256 private _latestSnapshotBlock;

    /**
     * @dev help clients getting latest data.
     */
    string private _latestSnapshotCid;

    /**
     * @dev create Snapper contract, init safeConfirmations and emit initial snapshot.
     */
    constructor(uint256 deploymentBlock_, string memory snapshotCid_) {
        _latestSnapshotBlock = deploymentBlock_;
        _latestSnapshotCid = snapshotCid_;

        emit Snapshot(_latestSnapshotBlock, snapshotCid_);
    }

    /**
     * @dev take snapshot. use lastSnapshotBlock_ to validate precondition.
     * @param lastSnapshotBlock_ block number last snapshot of.
     * @param snapshotBlock_ block number this snapshot of,
     */
    function takeSnapshot(
        uint256 lastSnapshotBlock_,
        uint256 snapshotBlock_,
        string calldata snapshotCid_,
        string calldata deltaCid_
    ) external onlyOwner {
        require(
            lastSnapshotBlock_ == _latestSnapshotBlock,
            "`lastSnapshotBlock_` must be equal to `latestSnapshotBlock` returned by `latestSnapshotInfo`"
        );
        require(
            snapshotBlock_ > lastSnapshotBlock_,
            "`snapshotBlock_` must be greater than `latestSnapshotBlock` returned by `latestSnapshotInfo`"
        );

        _latestSnapshotBlock = snapshotBlock_;
        _latestSnapshotCid = snapshotCid_;

        emit Snapshot(snapshotBlock_, snapshotCid_);
        emit Delta(snapshotBlock_, deltaCid_);
    }

    /**
     * @dev used by clients get the lastest snapshot info.
     */
    function latestSnapshotInfo() external view returns (uint256 latestSnapshotBlock, string memory latestSnapshotCid) {
        return (_latestSnapshotBlock, _latestSnapshotCid);
    }
}
