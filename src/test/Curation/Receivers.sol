//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

contract Acceptor {
    receive() external payable {}
}

contract Rejector {
    receive() external payable {
        require(false, "UNRECEIVABLE");
    }
}
