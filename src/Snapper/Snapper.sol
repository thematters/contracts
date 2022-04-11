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
     * @param block this delta end at this block, inclusive
     * @param cid ipfs content hash for this delta
     */
    event Delta(uint256 indexed block, string cid);

    /**
     * @dev Transactions with confirmations greater than or equal to this value are considered being finalized.
     *      Note that Transactions in latest block have 1 block confirmation.
     */
    uint256 public safeConfirmations;

    /**
     * @dev last snapshot toBlock num.
     */
    uint256 public lastToBlock;

    /**
     * @dev help clients getting latest events.
     */
    uint256 public latestEventBlock;

    /**
     * @dev create Snapper contract, init safeConfirmations.
     */
    constructor(uint256 safeConfirmations_) {
        safeConfirmations = safeConfirmations_;
    }

    /**
     * @dev set safeConfirmations.
     */
    function setSafeConfirmations(uint256 safeConfirmations_) external onlyOwner {
        safeConfirmations = safeConfirmations_;
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
        require(toBlock_ + safeConfirmations < block.number + 2, "target contain unstable blocks");

        emit Snapshot(toBlock_, snapshotCid_);
        emit Delta(toBlock_, deltaCid_);

        lastToBlock = toBlock_;
        latestEventBlock = block.number;
    }
}
