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
        distribution.setAdmin(USER);
    }

    function testCannotSetAdminByAttacker() public {
        vm.prank(ATTACKER);
        vm.expectRevert("Ownable: caller is not the owner");
        distribution.setAdmin(USER);
    }

    function testDrop() public {}
}
