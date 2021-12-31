//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IPaymentSplitter {
    /**
     * @notice Emitted when a royalty payment is made
     * @param tokenId token id
     * @param sender sender address
     * @param recipient recipient address
     * @param purpose purpose of the payment, e.g. fork, donate
     * @param amount amount of the payment
     */
    event Pay(
        uint256 indexed tokenId,
        address indexed sender,
        address indexed recipient,
        string purpose, // fork or donate
        uint256 amount
    );

    /**
     * @notice Emitted when a withdrawal is made
     * @param account address that receives the withdrawal
     * @param amount amount of the withdrawal
     */
    event Withdraw(address indexed account, uint256 amount);

    /**
     * @notice Withdraw royalty fee
     * @dev Emits a {Withdraw} event
     */
    function withdraw() external;

    /**
     * @notice Withdraw contract royalty fee
     * @dev Only contract owner can call 
     * @dev Emits a {Withdraw} event
     */
    function _withdrawContractFees() external;

    /**
     * @notice Get balance of a given address
     * @param account_ address
     */
    function getBalance(address account_) external returns (uint256);
}
