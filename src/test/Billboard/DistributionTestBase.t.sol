//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import {Distribution} from "../../Billboard/Distribution.sol";
import {IDistribution} from "../../Billboard/IDistribution.sol";

contract DistributionTestBase is Test {
    Distribution internal distribution;

    address constant ZERO_ADDRESS = address(0);
    address constant FAKE_CONTRACT = address(1);

    address constant OWNER = address(100);
    address constant ADMIN = address(101);
    address constant USER_ALICE = address(102);
    address constant USER_BOB = address(103);
    address constant USER_CHARLIE = address(104);
    address constant ATTACKER = address(200);

    bytes32 constant TREE_1_ROOT = 0x12c628670e93b44e4305c14af8efd4989e78cd5e9cbfa7f8b792326d08271b89;
    mapping(address => bytes32[]) public TREE_1_PROOFS;
    mapping(address => string) public TREE_1_CIDS;
    mapping(address => uint256) public TREE_1_AMOUNTS;

    function setUp() public {
        vm.startPrank(OWNER);

        // init proofs
        bytes32[] memory proofAlice = new bytes32[](1);
        proofAlice[0] = 0xf9b6aef995735ac234dd8f82c58b902f63846b2e900756d78ac93f5cab9acdd5;
        TREE_1_PROOFS[USER_ALICE] = proofAlice;

        bytes32[] memory proofBob = new bytes32[](2);
        proofBob[0] = 0xe3908a942209f327ea24b807c861c449d5994b50d152e447c1282fc6190d742d;
        proofBob[1] = 0xf23837c66d3ebf279f5f0a5ea3ee937887d05da50cb7f57d2009ce5058d4695c;
        TREE_1_PROOFS[USER_BOB] = proofBob;

        bytes32[] memory proofCharlie = new bytes32[](2);
        proofCharlie[0] = 0xa88b11df30bc3ccfee7a51d2e7d0a65ca0a7c5a2272ce4a65c27b65141916fc6;
        proofCharlie[1] = 0xf23837c66d3ebf279f5f0a5ea3ee937887d05da50cb7f57d2009ce5058d4695c;
        TREE_1_PROOFS[USER_BOB] = proofCharlie;

        // init cids
        TREE_1_CIDS[USER_ALICE] = "Qmf5z5DKcwNWYUP9udvnSCTN2Se4A8kpZJY7JuUVFEqdGU";
        TREE_1_CIDS[USER_BOB] = "QmSAwncsWGXeqwrL5USBzQXvjqfH1nFfARLGM91sfd4NZe";
        TREE_1_CIDS[USER_CHARLIE] = "QmUQQSeWxcqoNLKroGtz137c7QBWpzbNr9RcqDtVzZxJ3x";

        // init amounts
        TREE_1_AMOUNTS[USER_ALICE] = 1000000000000000000;
        TREE_1_AMOUNTS[USER_BOB] = 500000000000000000;
        TREE_1_AMOUNTS[USER_CHARLIE] = 10000000000000000;

        // deploy
        distribution = new Distribution();
        assertEq(distribution.admin(), OWNER);

        // set admin
        distribution.setAdmin(ADMIN);

        vm.stopPrank();
    }

    function drop(uint256 amount_) public {
        vm.prank(ADMIN);
        vm.deal(ADMIN, amount_);
        distribution.drop{value: amount_}(TREE_1_ROOT, amount_);
    }
}
