//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {DSTest} from "ds-test/test.sol";
import {console} from "./utils/Console.sol";
import {Logbook} from "../contracts/Logbook/Logbook.sol";

contract LogbookTest is DSTest {
    Logbook private logbook;

    function setUp() public {
        logbook = new Logbook("Logbook", "LBK");
    }

    function testPrint() public {
        console.log("test done.");
    }
}
