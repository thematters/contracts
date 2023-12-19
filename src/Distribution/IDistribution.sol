// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IDistribution {
    /**
     * @dev Emitted when an airdrop is claimed for an `account_`.
     * in the merkle tree, `amount_` is the amount of tokens claimed and transferred.
     * @param treeId_ Tree ID
     * @param account_ Address of claim
     * @param amount_ Amount of claim
     */
    event Claimed(uint256 treeId_, address indexed account_, uint256 amount_);

    /**
     * Returns the address of the token distributed by this contract.
     */
    function token() external view returns (address);

    /**
     * Returns the merkle root of a given `treeId_` merkle tree containing
     * account balances available to claim.
     *
     * @param treeId_ Tree ID
     *
     */
    function merkleRoot(uint256 treeId_) external view returns (bytes32);

    /**
     * @notice Claim and transfer tokens
     *
     * Verifies the provided proof and params
     * and transfers 'amount_' of tokens to 'account_'.
     *
     * @param treeId_ Tree ID
     * @param account_ Address of claim
     * @param amount_ Amount of claim
     * @param proof_ Merkle proof for (treeId_, account_, amount_)
     *
     * Emits a {Claimed} event on success.
     */
    function claim(uint256 treeId_, address account_, uint256 amount_, bytes32[] calldata proof_) external;

    /**
     * @notice Sweep any unclaimed funds
     *
     * Transfers the full tokenbalance from the distributor contract to `target_` address.
     *
     * @param treeId_ Tree ID
     * @param target_ Address that should receive the unclaimed funds
     */
    function sweep(uint256 treeId_, address target_) external;

    /**
     * @notice Sweep any unclaimed funds to owner address
     *
     * Transfers the full tokenbalance from the distributor contract to owner of contract.
     *
     * @param treeId_ Tree ID
     */
    function sweepToOwner(uint256 treeId_) external;
}
