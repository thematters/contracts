// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Snapper is Ownable {
    /**
     * @notice snapshot info
     * @param block the block number the snapshot of.
     * @param cid IPFS CID of the snapshot file.
     */
    event Snapshot(uint256 indexed block, string cid);

    /**
     * @notice delta info
     * @param block delta end at this block number, inclusive
     * @param cid IPFS CID of the delta file.
     */
    event Delta(uint256 indexed block, string cid);

    /**
     * @dev store latest snapshot info.
     */
    uint256 private _latestSnapshotBlock;
    string private _latestSnapshotCid;

    /**
     * @notice create Snapper contract, init safeConfirmations and emit initial snapshot.
     * @dev Emits {Snapshot} event.
     * @param theSpaceCreationBlock_ the Contract Creation block number of The Space contract.
     * @param snapshotCid_ the initial pixels picture IPFS CID of The Space.
     */
    constructor(uint256 theSpaceCreationBlock_, string memory snapshotCid_) {
        _latestSnapshotBlock = theSpaceCreationBlock_;
        _latestSnapshotCid = snapshotCid_;

        emit Snapshot(_latestSnapshotBlock, snapshotCid_);
    }

    /**
     * @dev Emits {Snapshot} and {Delta} events.
     * @param lastSnapshotBlock_ the block number last snapshot of. use to validate precondition.
     * @param snapshotBlock_ the block number the snapshot of,
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
            snapshotBlock_ > _latestSnapshotBlock,
            "`snapshotBlock_` must be greater than `latestSnapshotBlock` returned by `latestSnapshotInfo`"
        );

        _latestSnapshotBlock = snapshotBlock_;
        _latestSnapshotCid = snapshotCid_;

        emit Snapshot(snapshotBlock_, snapshotCid_);
        emit Delta(snapshotBlock_, deltaCid_);
    }

    /**
     * @dev get the lastest snapshot info.
     */
    function latestSnapshotInfo() external view returns (uint256 latestSnapshotBlock, string memory latestSnapshotCid) {
        return (_latestSnapshotBlock, _latestSnapshotCid);
    }
}
