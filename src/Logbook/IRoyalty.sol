//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @title The interface for NFT royalty
 */
interface IRoyalty {
    enum RoyaltyPurpose {
        Fork,
        Donate
    }

    /**
     * @notice Emitted when a royalty payment is made
     * @param tokenId Token id
     * @param sender Sender address
     * @param recipient Recipient address
     * @param purpose Purpose of the payment, e.g. fork, donate
     * @param amount Amount of the payment
     */
    event Pay(
        uint256 indexed tokenId,
        address indexed sender,
        address indexed recipient,
        RoyaltyPurpose purpose,
        uint256 amount
    );

    /**
     * @notice Emitted when a withdrawal is made
     * @param account Address that receives the withdrawal
     * @param amount Amount of the withdrawal
     */
    event Withdraw(address indexed account, uint256 amount);

    /**
     * @notice Withdraw royalty fees
     * @dev Emits a {Withdraw} event
     */
    function withdraw() external;

    /**
     * @notice Withdraw contract royalty fees
     * @dev Only contract owner can call
     * @dev Emits a {Withdraw} event
     */
    function withdrawContractFees() external;

    /**
     * @notice Get balance of a given address
     * @param account_ Address
     */
    function getBalance(address account_) external view returns (uint256);

    // TBD: support ERC-20 tokens,
    // more easy to spam or attack withdraw (pay more gas fee)?
}
