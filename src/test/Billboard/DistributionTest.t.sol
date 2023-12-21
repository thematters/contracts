//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./DistributionTestBase.t.sol";

contract DistributionTest is DistributionTestBase {
    function testSetAdmin() public {
        vm.prank(OWNER);
        distribution.setAdmin(ADMIN);
        assertEq(distribution.admin(), ADMIN);
    }

    function testCannotSetAdminByAdmin() public {
        vm.prank(OWNER);
        distribution.setAdmin(ADMIN);
        assertEq(distribution.admin(), ADMIN);

        vm.prank(ADMIN);
        vm.expectRevert("Ownable: caller is not the owner");
        distribution.setAdmin(USER_ALICE);
    }

    function testCannotSetAdminByAttacker() public {
        vm.prank(ATTACKER);
        vm.expectRevert("Ownable: caller is not the owner");
        distribution.setAdmin(USER_ALICE);
    }

    function testDrop() public {
        // drop#1
        uint256 _amount = 1510000000000000000;
        drop(_amount);
        assertEq(distribution.lastTreeId(), 1);
        assertEq(distribution.merkleRoots(1), TREE_1_ROOT);
        assertEq(distribution.balances(1), _amount);
        assertEq(usdt.balanceOf(address(distribution)), _amount);

        // drop#2
        drop(_amount);
        assertEq(distribution.lastTreeId(), 2);
        assertEq(distribution.merkleRoots(2), TREE_1_ROOT);
        assertEq(distribution.balances(2), _amount);
        assertEq(usdt.balanceOf(address(distribution)), _amount * 2);
    }

    function testCannotDropIfInsufficientAllowance(uint256 amount_) public {
        vm.assume(amount_ > 0);
        deal(address(usdt), ADMIN, amount_);

        vm.startPrank(ADMIN);
        usdt.approve(address(distribution), amount_ - 1);

        vm.expectRevert("ERC20: insufficient allowance");
        distribution.drop(TREE_1_ROOT, amount_);
    }

    function testCannotDropIfInsufficientBalance(uint256 amount_) public {
        vm.assume(amount_ > 0);
        vm.assume(amount_ < type(uint256).max);
        deal(address(usdt), ADMIN, amount_);

        vm.startPrank(ADMIN);
        usdt.approve(address(distribution), amount_ + 1);

        vm.expectRevert("ERC20: transfer amount exceeds balance");
        distribution.drop(TREE_1_ROOT, amount_ + 1);
    }

    function testClaim() public {
        // drop#1
        uint256 _amount = 1510000000000000000;
        drop(_amount);

        // claim#Alice
        uint256 balanceAlce = address(USER_ALICE).balance;
        distribution.claim(
            1,
            TREE_1_CIDS[USER_ALICE],
            USER_ALICE,
            TREE_1_AMOUNTS[USER_ALICE],
            TREE_1_PROOFS[USER_ALICE]
        );
        assertEq(usdt.balanceOf(address(USER_ALICE)), balanceAlce + TREE_1_AMOUNTS[USER_ALICE]);

        // claim#Bob
        uint256 balanceBob = address(USER_BOB).balance;
        distribution.claim(1, TREE_1_CIDS[USER_BOB], USER_BOB, TREE_1_AMOUNTS[USER_BOB], TREE_1_PROOFS[USER_BOB]);
        assertEq(usdt.balanceOf(address(USER_BOB)), balanceBob + TREE_1_AMOUNTS[USER_BOB]);

        // claim#Charlie
        uint256 balanceCharlie = address(USER_CHARLIE).balance;
        distribution.claim(
            1,
            TREE_1_CIDS[USER_CHARLIE],
            USER_CHARLIE,
            TREE_1_AMOUNTS[USER_CHARLIE],
            TREE_1_PROOFS[USER_CHARLIE]
        );
        assertEq(usdt.balanceOf(address(USER_CHARLIE)), balanceCharlie + TREE_1_AMOUNTS[USER_CHARLIE]);

        // check balance
        assertEq(address(distribution).balance, 0);
    }
}
