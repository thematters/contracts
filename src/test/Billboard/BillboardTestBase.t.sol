//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import {Billboard} from "../../Billboard/Billboard.sol";
import {BillboardRegistry} from "../../Billboard/BillboardRegistry.sol";
import {IBillboard} from "../../Billboard/IBillboard.sol";
import {IBillboardRegistry} from "../../Billboard/IBillboardRegistry.sol";

contract BillboardTestBase is Test {
    Billboard internal operator;
    BillboardRegistry internal registry;

    uint256 constant TAX_RATE = 1;

    address constant ZERO_ADDRESS = address(0);
    address constant FAKE_CONTRACT = address(1);

    /// Deployer and admin could be the same one
    address constant ADMIN = address(100);
    address constant USER_A = address(101);
    address constant USER_B = address(102);
    address constant USER_C = address(103);
    address constant ATTACKER = address(200);

    function setUp() public {
        vm.startPrank(ADMIN);

        // deploy operator & registry
        operator = new Billboard(address(0), TAX_RATE, "BLBD", "BLBD");
        registry = operator.registry();
        assertEq(operator.admin(), ADMIN);
        assertEq(registry.operator(), address(operator));

        vm.stopPrank();
    }

    function _mintBoard(address to_) public returns (uint256 tokenId) {
        vm.prank(ADMIN);
        tokenId = operator.mintBoard(to_);
        assertEq(registry.balanceOf(ADMIN), 1);
    }
}
