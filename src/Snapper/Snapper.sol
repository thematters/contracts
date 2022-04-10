// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Snapper is Ownable {
    /**
     * @notice snapshot info
     * @param block block number for this snapshot
     * @param cid ipfs content hash for this snapshot
     */
    event Snapshot(uint256 indexed block, string cid);

    /**
     * @notice delta info
     * @param fromBlock this delta start at this block, inclusive
     * @param toBlock this delta end at this block, inclusive
     * @param cid ipfs content hash for this delta
     */
    event Delta(uint256 indexed fromBlock, uint256 indexed toBlock, string cid);

    /**
     * @dev use to calculate the latest stable block number.
     */
    uint256 public confirmations;

    /**
     * @dev last snapshot toBlock num.
     */
    uint256 public lastToBlock;

    /**
     * @dev help clients getting latest events.
     */
    uint256 public latestEventBlock;

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

    /**
     * @dev take snapshot. use fromBlock_ to validate precondition.
     * @param fromBlock_ snapshot delta start at this block num, inclusive
     * @param toBlock_ snapshot delta end at this block num, inclusive
     */
    function takeSnapshot(
        uint256 fromBlock_,
        uint256 toBlock_,
        string calldata snapshotCid_,
        string calldata deltaCid_
    ) external onlyOwner {
        if (lastToBlock > 0) {
            require(fromBlock_ == lastToBlock + 1, "fromBlock must be lastToBlock + 1");
        }
        require(toBlock_ >= fromBlock_, "toBlock must be greater than or equal to fromBlock");
        require(toBlock_ + confirmations < block.number + 2, "target contain unstable blocks");

        emit Snapshot(toBlock_, snapshotCid_);
        emit Delta(fromBlock_, toBlock_, deltaCid_);

        lastToBlock = toBlock_;
        latestEventBlock = block.number;
    }
}
