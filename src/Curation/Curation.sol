//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./ICuration.sol";

contract Curation is ICuration {
    /**
     * @notice See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId_) external view virtual returns (bool) {
        return interfaceId_ == type(ICuration).interfaceId;
    }

    /// @inheritdoc ICuration
    function curate(
        address creator_,
        IERC20 token_,
        uint256 amount_,
        string calldata uri_
    ) public {
        if (creator_ == address(0)) revert ZeroAddress();
        if (amount_ <= 0) revert ZeroAmount();
        if (bytes(uri_).length == 0) revert InvalidURI();
        if (msg.sender == creator_) revert SelfCuration();

        SafeERC20.safeTransferFrom(token_, msg.sender, creator_, amount_);

        emit Curation(msg.sender, creator_, uri_, token_, amount_);
    }

    /// @inheritdoc ICuration
    function curate(address creator_, string calldata uri_) public payable {
        if (creator_ == address(0)) revert ZeroAddress();
        if (msg.value <= 0) revert ZeroAmount();
        if (bytes(uri_).length == 0) revert InvalidURI();
        if (msg.sender == creator_) revert SelfCuration();

        (bool success, ) = creator_.call{value: msg.value}("");
        require(success);

        emit Curation(msg.sender, creator_, uri_, msg.value);
    }
}
