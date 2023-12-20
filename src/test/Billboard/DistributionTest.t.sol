//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "./DistributionTestBase.t.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

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

        // drop#2
        drop(_amount);
        assertEq(distribution.lastTreeId(), 2);
        assertEq(distribution.merkleRoots(2), TREE_1_ROOT);
        assertEq(distribution.balances(2), _amount);
        assertEq(address(distribution).balance, _amount * 2);
    }
}
