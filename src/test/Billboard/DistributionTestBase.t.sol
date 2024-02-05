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

    bytes32 constant TREE_1_ROOT = 0xa0e4f659b6a70bfb30ef428b512e6823594648161125e32b8460a0ee3d52c463;
    mapping(address => bytes32[]) public TREE_1_PROOFS;
    mapping(address => string) public TREE_1_CIDS;
    mapping(address => uint256) public TREE_1_SHARES;

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
        proofAlice[0] = 0x44a23deeb3c7344ffa2627f200604092e44f07b09fbdb89d362ebc26ff8381db;
        TREE_1_PROOFS[USER_ALICE] = proofAlice;

        bytes32[] memory proofBob = new bytes32[](2);
        proofBob[0] = 0xa4a3eab5591f158e75b072a89e222cb6c926f47bc51347964573d924d5444b21;
        proofBob[1] = 0xcf0cc73dbba283908c5e905525f496c985e12f28d7424e9785d13955154126b8;
        TREE_1_PROOFS[USER_BOB] = proofBob;

        bytes32[] memory proofCharlie = new bytes32[](2);
        proofCharlie[0] = 0x70450d038737bb5828f2bbe807154a96b9f8fd1a3bf030a998d69b1d5e6e0d5f;
        proofCharlie[1] = 0xcf0cc73dbba283908c5e905525f496c985e12f28d7424e9785d13955154126b8;
        TREE_1_PROOFS[USER_CHARLIE] = proofCharlie;

        // init cids
        TREE_1_CIDS[USER_ALICE] = "Qmf5z5DKcwNWYUP9udvnSCTN2Se4A8kpZJY7JuUVFEqdGU";
        TREE_1_CIDS[USER_BOB] = "QmSAwncsWGXeqwrL5USBzQXvjqfH1nFfARLGM91sfd4NZe";
        TREE_1_CIDS[USER_CHARLIE] = "QmUQQSeWxcqoNLKroGtz137c7QBWpzbNr9RcqDtVzZxJ3x";

        // init shares
        TREE_1_SHARES[USER_ALICE] = 1000;
        TREE_1_SHARES[USER_BOB] = 2055;
        TREE_1_SHARES[USER_CHARLIE] = 6945;

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

    function drop(string memory treeId_, uint256 amount_) public {
        deal(address(usdt), ADMIN, amount_);
        vm.prank(ADMIN);
        distribution.drop(treeId_, TREE_1_ROOT, amount_);
    }
}
