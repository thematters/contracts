//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/console2.sol";
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

        // deploy operator
        operator = new Billboard();
        assertEq(ADMIN, operator.admin());
        address operatorAddress = address(operator);

        // deploy registry
        registry = new BillboardRegistry(operatorAddress, TAX_RATE, "BLBD", "BLBD");
        assertEq(operatorAddress, registry.operator());

        // upgrade registry
        operator.upgradeRegistry(address(registry));
        assertEq(address(registry), address(operator.registry()));
    }

    function _mintBoard() public {
        vm.stopPrank();
        vm.startPrank(ADMIN);

        // mint
        operator.mintBoard(ADMIN);
        assertEq(1, registry.balanceOf(ADMIN));
    }
}
