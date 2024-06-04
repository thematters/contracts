// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IVault {
    //////////////////////////////
    /// Error types
    //////////////////////////////

    error ZeroAddress();

    error ZeroAmount();

    error ZeroBalance();

    error ClaimExpired();

    error InvalidSignature();

    error AlreadyClaimed();

    //////////////////////////////
    /// Event types
    //////////////////////////////

    /**
     * @notice ETH deposited.
     * @param vaultId_ Vault ID to receive the ETH.
     * @param amount_ Amount of tokens that were deposited.
     * @param sender_ Address that deposited the ETH.
     */
    event Deposited(bytes32 indexed vaultId_, uint256 amount_, address indexed sender_);

    /**
     * @notice Tokens deposited.
     * @param vaultId_ Vault ID to receive the tokens.
     * @param token_ Token address.
     * @param amount_ Amount of tokens that were deposited.
     * @param sender_ Address that deposited the tokens.
     */
    event Deposited(bytes32 indexed vaultId_, address indexed token_, uint256 amount_, address indexed sender_);

    /**
     * @notice ETH claimed.
     * @param vaultId_ Vault ID of the claim.
     * @param target_ Address to receive the tokens.
     * @param amount_ Amount of tokens that were claimed.
     */
    event Claimed(bytes32 indexed vaultId_, address indexed target_, uint256 amount_);

    /**
     * @notice Tokens claimed.
     * @param vaultId_ Vault ID of the claim.
     * @param token_ Token address.
     * @param target_ Address to receive the tokens.
     * @param amount_ Amount of tokens that were claimed.
     */
    event Claimed(bytes32 indexed vaultId_, address indexed token_, address indexed target_, uint256 amount_);

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
    /// Deposit
    //////////////////////////////

    /**
     * @notice Deposit ETH.
     *
     * @dev Throws: `ZeroAmount` error
     * @dev Emits: `Deposited` events.
     *
     * @param vaultId_ Vault ID of the claim.
     */
    function deposit(bytes32 vaultId_) external payable;

    /**
     * @notice Deposit tokens.
     *
     * @dev Throws: `ZeroAmount` error
     * @dev Emits: `Deposited` events.
     *
     * @param vaultId_ Vault ID of the claim.
     * @param token_ Token address.
     * @param amount_ Amount of tokens to deposit.
     */
    function deposit(bytes32 vaultId_, address token_, uint256 amount_) external;

    //////////////////////////////
    /// Claim
    //////////////////////////////

    /**
     * Get the available ETH to claim of a vault.
     *
     * @param vaultId_ Vault ID of the claim.
     *
     * @return Amount of ETH available for the claim.
     */
    function available(bytes32 vaultId_) external view returns (uint256);

    /**
     * Get the available tokens to claim of a vault.
     *
     * @param vaultId_ Vault ID of the claim.
     * @param token_ Token address.
     *
     * @return Amount of tokens available for the claim.
     */
    function available(bytes32 vaultId_, address token_) external view returns (uint256);

    /**
     * @notice Claim ETH.
     *
     * @dev Throws: `ZeroBalance`, `ClaimExpired`, `InvalidSignature`,
     * or `AlreadyClaimed` error.
     * @dev Emits: `Claimed` events.
     *
     * @param vaultId_ Vault ID of the claim.
     * @param target_ Address to receive the ETH.
     * @param expiredAt_ Timestamp when the drop expires.
     * @param v_ Signature field.
     * @param r_ Signature field.
     * @param s_ Signature field.
     */
    function claim(bytes32 vaultId_, address target_, uint256 expiredAt_, uint8 v_, bytes32 r_, bytes32 s_) external;

    /**
     * @notice Claim tokens.
     *
     * @dev Throws: `ZeroBalance`, `ClaimExpired`, `InvalidSignature`
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
     */
    function claim(
        bytes32 vaultId_,
        address token_,
        address target_,
        uint256 expiredAt_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external;

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
