//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/console2.sol";
import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import {Billboard} from "../../Billboard/Billboard.sol";
import {BillboardAuction} from "../../Billboard/BillboardAuction.sol";
import {BillboardRegistry} from "../../Billboard/BillboardRegistry.sol";
import {IBillboard} from "../../Billboard/IBillboard.sol";
import {IBillboardRegistry} from "../../Billboard/IBillboardRegistry.sol";

contract BillboardTestBase is Test {
    Billboard internal operator;
    BillboardAuction internal auction;
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

        // deploy auction
        auction = new BillboardAuction(ADMIN, operatorAddress, TAX_RATE);
        assertEq(ADMIN, auction.admin());
        assertEq(operatorAddress, auction.operator());

        // deploy registry
        registry = new BillboardRegistry(ADMIN, operatorAddress, "BLBD", "BLBD");
        assertEq(ADMIN, registry.admin());
        assertEq(operatorAddress, registry.operator());

        // upgrade auction
        operator.upgradeAuction(address(auction));
        assertEq(address(auction), address(operator.auction()));

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