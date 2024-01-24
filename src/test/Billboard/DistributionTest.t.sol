//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./DistributionTestBase.t.sol";

contract DistributionTest is DistributionTestBase {
    //////////////////////////////
    /// Access control
    //////////////////////////////

    function testSetAdmin() public {
        vm.prank(OWNER);

        vm.expectEmit(true, true, false, false);
        emit IDistribution.AdminChanged(ADMIN, USER_ALICE);

        distribution.setAdmin(USER_ALICE);
        assertEq(distribution.admin(), USER_ALICE);
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

    //////////////////////////////
    /// Drop
    //////////////////////////////

    function testDrop() public {
        // drop#1
        uint256 _totalAmount = 1510000000000000000;
        drop(_totalAmount);
        assertEq(distribution.lastTreeId(), 1);
        assertEq(distribution.merkleRoots(1), TREE_1_ROOT);
        assertEq(distribution.balances(1), _totalAmount);
        assertEq(usdt.balanceOf(address(distribution)), _totalAmount);

        // drop#2
        drop(_totalAmount);
        assertEq(distribution.lastTreeId(), 2);
        assertEq(distribution.merkleRoots(2), TREE_1_ROOT);
        assertEq(distribution.balances(2), _totalAmount);
        assertEq(usdt.balanceOf(address(distribution)), _totalAmount * 2);
    }

    function testCannotDropByAttacker() public {
        vm.prank(ATTACKER);
        vm.expectRevert("Admin");
        distribution.drop(TREE_1_ROOT, 1);
    }

    function testCannotDropIfZeroAmount() public {
        deal(address(usdt), ADMIN, 0);
        vm.prank(ADMIN);
        vm.expectRevert("Zero amount");
        distribution.drop(TREE_1_ROOT, 0);
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

    //////////////////////////////
    /// Claim
    //////////////////////////////
    function testClaim() public {
        // drop#1
        uint256 _totalAmount = 1510000000000000000;
        drop(_totalAmount);

        // claim#Alice
        uint256 _amount = distribution.calculateAmount(TREE_1_SHARES[USER_ALICE], _totalAmount);
        vm.expectEmit(true, true, false, false);
        emit IDistribution.Claim(TREE_1_CIDS[USER_ALICE], USER_ALICE, _amount);
        uint256 balanceAlce = address(USER_ALICE).balance;
        distribution.claim(
            1,
            TREE_1_CIDS[USER_ALICE],
            USER_ALICE,
            TREE_1_SHARES[USER_ALICE],
            TREE_1_PROOFS[USER_ALICE]
        );
        assertEq(usdt.balanceOf(address(USER_ALICE)), balanceAlce + _amount);
        assertEq(usdt.balanceOf(address(distribution)), _totalAmount - _amount);

        // claim#Bob
        uint256 _amountBob = distribution.calculateAmount(TREE_1_SHARES[USER_BOB], _totalAmount);
        vm.expectEmit(true, true, false, false);
        emit IDistribution.Claim(TREE_1_CIDS[USER_BOB], USER_BOB, _amountBob);
        uint256 balanceBob = address(USER_BOB).balance;
        distribution.claim(1, TREE_1_CIDS[USER_BOB], USER_BOB, TREE_1_SHARES[USER_BOB], TREE_1_PROOFS[USER_BOB]);
        assertEq(usdt.balanceOf(address(USER_BOB)), balanceBob + _amountBob);

        // claim#Charlie
        uint256 _amountCharlie = distribution.calculateAmount(TREE_1_SHARES[USER_CHARLIE], _totalAmount);
        vm.expectEmit(true, true, false, false);
        emit IDistribution.Claim(TREE_1_CIDS[USER_CHARLIE], USER_CHARLIE, _amountCharlie);
        uint256 balanceCharlie = address(USER_CHARLIE).balance;
        distribution.claim(
            1,
            TREE_1_CIDS[USER_CHARLIE],
            USER_CHARLIE,
            TREE_1_SHARES[USER_CHARLIE],
            TREE_1_PROOFS[USER_CHARLIE]
        );
        assertEq(usdt.balanceOf(address(USER_CHARLIE)), balanceCharlie + _amountCharlie);

        // check balance
        assertEq(address(distribution).balance, 0);
    }

    function testCannotClaimIfAlreadyClaimed() public {
        // drop#1
        uint256 _totalAmount = 1510000000000000000;
        drop(_totalAmount);

        // claim#Alice
        distribution.claim(
            1,
            TREE_1_CIDS[USER_ALICE],
            USER_ALICE,
            TREE_1_SHARES[USER_ALICE],
            TREE_1_PROOFS[USER_ALICE]
        );

        // claim#Alice again
        vm.expectRevert("Already claimed");
        distribution.claim(
            1,
            TREE_1_CIDS[USER_ALICE],
            USER_ALICE,
            TREE_1_SHARES[USER_ALICE],
            TREE_1_PROOFS[USER_ALICE]
        );
    }

    function testCannotClaimIfInvalidProof() public {
        // drop#1
        uint256 _totalAmount = 1510000000000000000;
        drop(_totalAmount);

        // claim#Alice
        uint256 _amount = distribution.calculateAmount(TREE_1_SHARES[USER_ALICE], _totalAmount);
        vm.expectRevert("Invalid proof");
        distribution.claim(1, TREE_1_CIDS[USER_ALICE], USER_ALICE, _amount, TREE_1_PROOFS[USER_BOB]);
    }

    function testCannotClaimIfInvalidTreeId() public {
        // drop#1
        uint256 _totalAmount = 1510000000000000000;
        drop(_totalAmount);

        // claim#Alice
        vm.expectRevert("Invalid tree ID");
        distribution.claim(
            2,
            TREE_1_CIDS[USER_ALICE],
            USER_ALICE,
            TREE_1_SHARES[USER_ALICE],
            TREE_1_PROOFS[USER_ALICE]
        );
    }

    function testCannotClaimIfInsufficientBalance() public {
        // drop#1
        uint256 _totalAmount = 1510000000000000000;
        drop(_totalAmount);
        deal(address(usdt), address(distribution), 0);
        assertEq(usdt.balanceOf(address(distribution)), 0);

        // claim#Alice
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        distribution.claim(
            1,
            TREE_1_CIDS[USER_ALICE],
            USER_ALICE,
            TREE_1_SHARES[USER_ALICE],
            TREE_1_PROOFS[USER_ALICE]
        );
    }

    //////////////////////////////
    /// Sweep
    //////////////////////////////
    function testSweep() public {
        // drop
        uint256 _totalAmount = 1510000000000000000;
        drop(_totalAmount);

        // sweep
        uint256 prevBalance = usdt.balanceOf(ADMIN);
        vm.prank(ADMIN);
        distribution.sweep(1, ADMIN);
        assertEq(usdt.balanceOf(ADMIN), prevBalance + _totalAmount);
        assertEq(usdt.balanceOf(address(distribution)), 0);
        assertEq(distribution.balances(1), 0);
    }

    function testCannotSweepByAttacker() public {
        // drop
        uint256 _totalAmount = 1510000000000000000;
        drop(_totalAmount);

        // sweep
        vm.prank(ATTACKER);
        vm.expectRevert("Admin");
        distribution.sweep(1, ADMIN);
    }

    function testCannotSweepIfZeroBalance() public {
        // drop
        uint256 _totalAmount = 1510000000000000000;
        drop(_totalAmount);

        // sweep
        vm.prank(ADMIN);
        vm.expectRevert("Zero balance");
        distribution.sweep(2, ADMIN);
    }
}
