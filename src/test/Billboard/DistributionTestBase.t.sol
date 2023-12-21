//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import {Distribution} from "../../Billboard/Distribution.sol";
import {IDistribution} from "../../Billboard/IDistribution.sol";
import {USDT} from "../utils/USDT.sol";

contract DistributionTestBase is Test {
    Distribution internal distribution;
    USDT internal usdt;

    address constant ZERO_ADDRESS = address(0);
    address constant FAKE_CONTRACT = address(1);

    address constant OWNER = address(100);
    address constant ADMIN = address(101);
    address constant USER_ALICE = address(102);
    address constant USER_BOB = address(103);
    address constant USER_CHARLIE = address(104);
    address constant ATTACKER = address(200);

    bytes32 constant TREE_1_ROOT = 0xf2e79881fa5ed7db88877ca21ec885996d6176cf455504472b68f5517203e314;
    mapping(address => bytes32[]) public TREE_1_PROOFS;
    mapping(address => string) public TREE_1_CIDS;
    mapping(address => uint256) public TREE_1_AMOUNTS;

    function setUp() public {
        vm.startPrank(OWNER);

        // label addresses
        vm.label(OWNER, "OWNER");
        vm.label(ADMIN, "ADMIN");
        vm.label(USER_ALICE, "USER_ALICE");
        vm.label(USER_BOB, "USER_BOB");
        vm.label(USER_CHARLIE, "USER_CHARLIE");

        // init proofs
        bytes32[] memory proofAlice = new bytes32[](1);
        proofAlice[0] = 0x884512338d5de33ee9c6e0a1c2a47ff1c8ca788bbb8b34552e39cb98aaaa5c08;
        TREE_1_PROOFS[USER_ALICE] = proofAlice;

        bytes32[] memory proofBob = new bytes32[](2);
        proofBob[0] = 0x685ad0f74cc48ff99f8fa41d3f8d2e3c7672e7afe48a680c9418b7268626fc89;
        proofBob[1] = 0xfa171588c56e80a41d8e67e9c9a8dc6b25dbdf1e16699c612981ebdf04045c3f;
        TREE_1_PROOFS[USER_BOB] = proofBob;

        bytes32[] memory proofCharlie = new bytes32[](2);
        proofCharlie[0] = 0x27349dbdeb528d38831624696ac843c93d915cbf47db44f6087b3e431152c4de;
        proofCharlie[1] = 0xfa171588c56e80a41d8e67e9c9a8dc6b25dbdf1e16699c612981ebdf04045c3f;
        TREE_1_PROOFS[USER_CHARLIE] = proofCharlie;

        // init cids
        TREE_1_CIDS[USER_ALICE] = "Qmf5z5DKcwNWYUP9udvnSCTN2Se4A8kpZJY7JuUVFEqdGU";
        TREE_1_CIDS[USER_BOB] = "QmSAwncsWGXeqwrL5USBzQXvjqfH1nFfARLGM91sfd4NZe";
        TREE_1_CIDS[USER_CHARLIE] = "QmUQQSeWxcqoNLKroGtz137c7QBWpzbNr9RcqDtVzZxJ3x";

        // init amounts
        TREE_1_AMOUNTS[USER_ALICE] = 1000000000000000000;
        TREE_1_AMOUNTS[USER_BOB] = 500000000000000000;
        TREE_1_AMOUNTS[USER_CHARLIE] = 10000000000000000;

        // deploy USDT
        usdt = new USDT(OWNER, 0);

        // deploy Distribution contract
        distribution = new Distribution(address(usdt), ADMIN);
        assertEq(distribution.admin(), ADMIN);

        vm.stopPrank();

        // approve USDT
        uint256 MAX_ALLOWANCE = type(uint256).max;
        vm.prank(ADMIN);
        usdt.approve(address(distribution), MAX_ALLOWANCE);
        vm.prank(USER_ALICE);
        usdt.approve(address(distribution), MAX_ALLOWANCE);
        vm.prank(USER_BOB);
        usdt.approve(address(distribution), MAX_ALLOWANCE);
        vm.prank(USER_CHARLIE);
        usdt.approve(address(distribution), MAX_ALLOWANCE);
    }

    function drop(uint256 amount_) public {
        deal(address(usdt), ADMIN, amount_);
        vm.prank(ADMIN);
        distribution.drop(TREE_1_ROOT, amount_);
    }
}
