// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IDistribution {
    /**
     * @dev Emitted when an new drop is created.
     *
     * @param treeId_ Tree ID of the drop
     * @param amount_ Total amount of the drop
     */
    event Drop(string indexed treeId_, uint256 amount_);

    /**
     * @dev Emitted when an claim is made.
     *
     * @param cid_ Content ID of claim
     * @param account_ Address of claim
     * @param amount_ Amount of claim
     */
    event Claim(string indexed cid_, address indexed account_, uint256 amount_);

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
     * @param treeId_ Tree ID of new drop
     * @param merkleRoot_ Merkle root of new drop
     * @param amount_ Total amount of new drop
     *
     * Emits a {Drop} event on success.
     */
    function drop(string calldata treeId_, bytes32 merkleRoot_, uint256 amount_) external;

    /**
     * @notice Claim and transfer tokens
     *
     * @param treeId_ Tree ID
     * @param cid_ Content ID
     * @param account_ Address of claim
     * @param share_ Share (percentage with two decimal places to an integer representation, 0-10000) of total amount
     * @param proof_ Merkle proof for (treeId_, cid_, account_, share_)
     *
     * Emits a {Claim} event on success.
     */
    function claim(
        string calldata treeId_,
        string calldata cid_,
        address account_,
        uint256 share_,
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
    function sweep(string calldata treeId_, address target_) external;
}
