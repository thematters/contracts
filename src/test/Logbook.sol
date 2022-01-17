//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "../Logbook/Logbook.sol";

contract LogbookTest is DSTest {
    Logbook logbook;

    function setUp() public {
        logbook = new Logbook("Logbook", "LBK");
    }

    function test() public {
       
    }
}