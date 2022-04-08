// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Snapper is Ownable {
    /**
     * @notice snapshot info
     * @param blocknum block number for this snapshot
     * @param cid ipfs content hash for this snapshot
     */
    event Snapshot(uint256 indexed blocknum, string cid);

    /**
     * @notice delta info
     * @param blocknum block number for this delta
     * @param cid ipfs content hash for this delta
     */
    event Delta(uint256 indexed blocknum, string cid);

    /**
     * @dev use to calculate the latest stable block number.
     */
    uint256 public confirmations;

    /**
     * @dev last snapshot toBlock num.
     */
    uint256 public lastToBlocknum;

    /**
     * @dev latest snapshot events block num.
     */
    uint256 public latestEventBlocknum;

    /**
     * @dev create Snapper contract, init confirmations.
     */
    constructor(uint256 confirmations_) {
        confirmations = confirmations_;
    }

    /**
     * @dev set confirmations.
     */
    function setConfirmations(uint256 confirmations_) external onlyOwner {
        confirmations = confirmations_;
    }

    function takeSnapshot(
        uint256 toBlocknum_,
        string calldata snapshotCid_,
        string calldata deltaCid_
    ) external onlyOwner {
        require(toBlocknum_ > lastToBlocknum, "toBlocknum must bigger than lastToBlocknum");
        require(toBlocknum_ + confirmations < block.number + 2, "target contain unstable blocks");

        emit Snapshot(toBlocknum_, snapshotCid_);
        emit Delta(toBlocknum_, deltaCid_);

        lastToBlocknum = toBlocknum_;
        latestEventBlocknum = block.number;
    }
}
