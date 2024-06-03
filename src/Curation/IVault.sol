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

    error AlreadyClaimed();

    error TransferFailed(address token_, address account_, uint256 amount_);

    //////////////////////////////
    /// Event types
    //////////////////////////////

    /**
     * @notice ETH claimed.
     * @param id_ Unique ID of the claim.
     * @param target_ Address to receive the tokens.
     * @param amount_ Amount of tokens that were claimed.
     */
    event Claimed(bytes32 indexed id_, address indexed target_, uint256 amount_);

    /**
     * @notice Tokens claimed.
     * @param id_ Unique ID of the claim.
     * @param token_ Token address.
     * @param target_ Address to receive the tokens.
     * @param amount_ Amount of tokens that were claimed.
     */
    event Claimed(bytes32 indexed id_, address indexed token_, address indexed target_, uint256 amount_);

    /**
     * @notice Unclaimed ETH were swept.
     * @param target_ Address that received the unclaimed funds.
     * @param amount_ Amount of tokens that were swept.
     */
    event Swept(address indexed target_, uint256 amount_);

    /**
     * @notice Unclaimed tokens were swept.
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
     * @notice Claim ETH.
     *
     * @dev Throws: `NotEnoughBalance`, `ClaimExpired`, `InvalidSignature`,
     * or `AlreadyClaimed` error.
     * @dev Emits: `Claimed` events.
     *
     * @param vaultId_ Vault ID of the claim.
     * @param target_ Address to receive the ETH.
     * @param expiredAt_ Timestamp when the drop expires.
     * @param v_ Signature field.
     * @param r_ Signature field.
     * @param s_ Signature field.
     * @return success Whether the claim was successful.
     */
    function claim(
        bytes32 vaultId_,
        address target_,
        uint256 expiredAt_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external returns (bool success);

    /**
     * @notice Claim tokens.
     *
     * @dev Throws: `NotEnoughBalance`, `ClaimExpired`, `InvalidSignature`
     * or `AlreadyClaimed` error.
     * @dev Emits: `Claimed` events.
     *
     * @param vaultId_ Vault ID of the claim.
     * @param token_ Token address.
     * @param target_ Address to receive the tokens.
     * @param expiredAt_ Timestamp when the drop expires.
     * @param v_ Signature field.
     * @param r_ Signature field.
     * @param s_ Signature field.
     * @return success Whether the claim was successful.
     */
    function claim(
        bytes32 vaultId_,
        address token_,
        address target_,
        uint256 expiredAt_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external returns (bool success);

    //////////////////////////////
    /// Sweep
    //////////////////////////////

    /**
     * @notice Sweep any unclaimed ETH
     * @dev Transfers ETH from the contract to `target_` address.
     *
     * @param target_ Address that should receive the unclaimed ETH
     */
    function sweep(address target_) external;

    /**
     * @notice Sweep any unclaimed tokens
     * @dev Transfers tokens from the contract to `target_` address.
     *
     * @param token_ Token address to sweep
     * @param target_ Address that should receive the unclaimed tokens
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
