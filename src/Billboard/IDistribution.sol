// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IDistribution {
    /**
     * @dev Emitted when an new drop is created.
     *
     * @param treeId_ Tree ID of the drop
     * @param amount_ Total amount of the drop
     */
    event Drop(uint256 indexed treeId_, uint256 amount_);

    /**
     * @dev Emitted when an claim is made.
     *
     * @param cid_ Content ID of claim
     * @param account_ Address of claim
     * @param amount_ Amount of claim
     */
    event Claim(bytes32 cid_, address indexed account_, uint256 amount_);

    /**
     * @dev Emitted when admin is changed.
     *
     * @param prevAccount_ Address of old admin
     * @param account_ Address of new admin
     */
    event AdminChanged(address indexed prevAccount_, address indexed account_);

    /**
     * @notice Set admin
     *
     * @param account_ Address of new admin
     *
     * Emits a {AdminChanged} event on success.
     */
    function setAdmin(address account_) external;

    /**
     * @notice Create a new drop
     *
     * @param merkleRoot_ Merkle root of new drop
     *
     * Emits a {Drop} event on success.
     */
    function drop(bytes32 merkleRoot_) external payable returns (uint256 treeId_);

    /**
     * @notice Claim and transfer tokens
     *
     * @param treeId_ Tree ID
     * @param cid_ Content ID
     * @param account_ Address of claim
     * @param amount_ Amount of claim
     * @param proof_ Merkle proof for (treeId_, cid_, account_, amount_)
     *
     * Emits a {Claim} event on success.
     */
    function claim(
        uint256 treeId_,
        bytes32 cid_,
        address account_,
        uint256 amount_,
        bytes32[] calldata proof_
    ) external;

    /**
     * @notice Sweep any unclaimed funds
     *
     * Transfers the full tokenbalance from the distributor contract to `target_` address.
     *
     * @param treeId_ Tree ID
     * @param target_ Address that should receive the unclaimed funds
     */
    function sweep(uint256 treeId_, address target_) external;
}
