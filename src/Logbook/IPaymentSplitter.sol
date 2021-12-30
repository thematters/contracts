//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;


interface IPaymentSplitter {
    event SplitPayment(
        uint256 indexed tokenId,
        address indexed sender,
        address indexed recipient,
        string purpose, // fork or donate
        uint256 amount
    );
    event Withdraw(address indexed payee, uint256 amount);

    /**
     * @dev Withdraws owner and co-creation fees.
     *
     * Emits a {Withdraw} event.
     */
    function withdraw() external;

    /**
     * @dev Withdraws royalty fees.
     *
     */
    function _withdrawRoyaltyFees() external;

    /**
     * @dev Get balance of a given address.
     *
     */
    function getBalance(address account) external returns (uint256);
}
