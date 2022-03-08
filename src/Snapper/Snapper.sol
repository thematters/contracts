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
     * @dev last snapshot block num.
     */
    uint256 public lastBlocknum;

    /**
     * @dev create Snapper contract, init confirmations.
     */
    constructor(uint256 confirmations_) {
        confirmations = confirmations_;
    }

    /**
     * @dev set confirmations.
     */
    function setConfirmations(uint256 confirmations_) external onlyOwner{
        confirmations = confirmations_;
    }

    function takeSnapshot(uint256 toBlocknum_, string calldata snapshotCid_, string calldata deltaCid_) external onlyOwner{
        require(toBlocknum_ > lastBlocknum, "toBlocknum must bigger than lastBlocknum");
        require(
            toBlocknum_ + confirmations  <= block.number,
            "target contain unstable blocks"
        );

        emit Snapshot(toBlocknum_, snapshotCid_);
        emit Delta(toBlocknum_, deltaCid_);

        lastBlocknum = toBlocknum_;
    }
}
