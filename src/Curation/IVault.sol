// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IVault {
    //////////////////////////////
    /// Error types
    //////////////////////////////

    error ZeroAddress();

    error ClaimExpired();

    error NotEnoughBalance();

    error InvalidSignature();

    error TransferFailed(address token_, address account_, uint256 amount_);

    //////////////////////////////
    /// Event types
    //////////////////////////////

    /**
     * @notice Tokens claimed.
     * @param id_ Unique ID of the claim.
     * @param token_ Token address.
     * @param target_ Address to receive the tokens.
     * @param amount_ Amount of tokens that were claimed.
     */
    event Claimed(bytes32 indexed id_, address indexed token_, address indexed target_, uint256 amount_);

    /**
     * @notice Unclaimed funds were swept.
     * @param token_ Token address.
     * @param target_ Address that received the unclaimed funds.
     * @param amount_ Amount of tokens that were swept.
     */
    event Swept(address indexed token_, address indexed target_, uint256 amount_);

    /**
     * @notice Signer is changed.
     * @param signer_ New signer.
     */
    event SignerChanged(address indexed signer_);

    //////////////////////////////
    /// Claim
    //////////////////////////////

    /**
     * @notice Claim tokens.
     *
     * @dev Throws: `NotEnoughBalance`, `ClaimExpired`, or `InvalidSignature` error.
     * @dev Emits: `Claimed` events.
     *
     * @param id_ Unique ID of the claim.
     * @param token_ Token address.
     * @param target_ Address to receive the tokens.
     * @param expiredAt_ Timestamp when the drop expires.
     * @param v_ Signature field.
     * @param r_ Signature field.
     * @param s_ Signature field.
     * @return success Whether the claim was successful.
     */
    function claim(
        bytes32 id_,
        address token_,
        address target_,
        uint256 expiredAt_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external returns (bool success);

    //////////////////////////////
    /// Withdraw
    //////////////////////////////

    /**
     * @notice Sweep any unclaimed funds
     * @dev Transfers tokens from the contract to `target_` address.
     *
     * @param token_ Token address to sweep
     * @param target_ Address that should receive the unclaimed funds
     */
    function sweep(address token_, address target_) external;

    //////////////////////////////
    /// Verify
    //////////////////////////////

    /**
     * @notice Set a new signer for the contract
     * @param signer_ Address of the new signer.
     */
    function setSigner(address signer_) external;
}
