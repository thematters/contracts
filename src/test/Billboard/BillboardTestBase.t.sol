//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import {USDT} from "../utils/USDT.sol";
import {Billboard} from "../../Billboard/Billboard.sol";
import {BillboardRegistry} from "../../Billboard/BillboardRegistry.sol";
import {IBillboard} from "../../Billboard/IBillboard.sol";
import {IBillboardRegistry} from "../../Billboard/IBillboardRegistry.sol";

contract BillboardTestBase is Test {
    Billboard internal operator;
    BillboardRegistry internal registry;
    USDT internal usdt;

    uint256 constant TAX_RATE = 1024; // 10.24% per epoch
    uint256 constant EPOCH_INTERVAL = 100; // 100 blocks

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

        // deploy USDT
        usdt = new USDT(ADMIN, 0);

        // deploy operator & registry
        operator = new Billboard(address(usdt), payable(address(0)), ADMIN, "Billboard", "BLBD");
        registry = operator.registry();
        assertEq(operator.admin(), ADMIN);
        assertEq(registry.operator(), address(operator));
        assertEq(registry.name(), "Billboard");
        assertEq(registry.symbol(), "BLBD");

        vm.stopPrank();

        // approve USDT
        uint256 MAX_ALLOWANCE = type(uint256).max;
        vm.prank(ADMIN);
        usdt.approve(address(operator), MAX_ALLOWANCE);
        vm.prank(USER_A);
        usdt.approve(address(operator), MAX_ALLOWANCE);
        vm.prank(USER_B);
        usdt.approve(address(operator), MAX_ALLOWANCE);
        vm.prank(USER_C);
        usdt.approve(address(operator), MAX_ALLOWANCE);
    }

    function _mintBoard() public returns (uint256 tokenId) {
        vm.prank(ADMIN);
        tokenId = operator.mintBoard(TAX_RATE, EPOCH_INTERVAL);
    }

    function _mintBoardAndPlaceBid() public returns (uint256 tokenId_, uint256 epoch_) {
        tokenId_ = _mintBoard();

        // (new board) ADMIN places first bid and takes the ownership
        vm.startPrank(ADMIN);
        operator.placeBid(tokenId_, epoch_, 0);
        assertEq(registry.higgestBidder(tokenId_, epoch_), ADMIN);

        // add USER_A and USER_B to whitelist
        operator.addToWhitelist(tokenId_, USER_A);
        operator.addToWhitelist(tokenId_, USER_B);
        vm.stopPrank();
    }
}
