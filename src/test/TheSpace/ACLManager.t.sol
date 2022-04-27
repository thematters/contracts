//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./BaseTheSpace.t.sol";

contract ACLManagerTest is BaseTheSpaceTest {
    address constant NEW_ACL_MANAGER = address(300);
    address constant NEW_MARKET_ADMIN = address(301);

    function testRoles() public {
        assertEq(thespace.hasRole(ROLE_ACL_MANAGER, ACL_MANAGER), true);
        assertEq(thespace.hasRole(ROLE_MARKET_ADMIN, MARKET_ADMIN), true);
        assertEq(thespace.hasRole(ROLE_TREASURY_ADMIN, TREASURY_ADMIN), true);
    }

    /**
     * Grant Role
     */
    function testGrantRole() public {
        assertEq(thespace.hasRole(ROLE_MARKET_ADMIN, NEW_MARKET_ADMIN), false);

        vm.stopPrank();
        vm.prank(ACL_MANAGER);
        thespace.grantRole(ROLE_MARKET_ADMIN, NEW_MARKET_ADMIN);

        // NEW_MARKET_ADMIN is now the market manager
        assertEq(thespace.hasRole(ROLE_MARKET_ADMIN, NEW_MARKET_ADMIN), true);

        // MARKET_ADMIN lost its role
        assertEq(thespace.hasRole(ROLE_MARKET_ADMIN, MARKET_ADMIN), false);
    }

    function testCannotGrantACLManagerRole() public {
        vm.stopPrank();
        vm.prank(ACL_MANAGER);

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        thespace.grantRole(ROLE_ACL_MANAGER, NEW_MARKET_ADMIN);
    }

    function testCannotGrantRoleToZeroAddress() public {
        vm.stopPrank();
        vm.prank(ACL_MANAGER);

        vm.expectRevert(abi.encodeWithSignature("ZeroAddress()"));
        thespace.grantRole(ROLE_MARKET_ADMIN, address(0));
    }

    function testCannotGrantRoleByNonACLManager() public {
        vm.stopPrank();

        // Prank market admin to grant role
        vm.expectRevert(abi.encodeWithSignature("RoleRequired(uint8)", ROLE_ACL_MANAGER));
        vm.prank(MARKET_ADMIN);
        thespace.grantRole(ROLE_MARKET_ADMIN, NEW_MARKET_ADMIN);

        // Prank attacker to grant role
        vm.expectRevert(abi.encodeWithSignature("RoleRequired(uint8)", ROLE_ACL_MANAGER));
        vm.prank(ATTACKER);
        thespace.grantRole(ROLE_MARKET_ADMIN, NEW_MARKET_ADMIN);
    }

    /**
     * Transfer Role
     */
    function testTransferRole() public {
        vm.stopPrank();

        assertEq(thespace.hasRole(ROLE_MARKET_ADMIN, MARKET_ADMIN), true);

        // Market admin transfers role to new market admin
        vm.prank(MARKET_ADMIN);
        thespace.transferRole(ROLE_MARKET_ADMIN, NEW_MARKET_ADMIN);

        // NEW_MARKET_ADMIN is now the market manager
        assertEq(thespace.hasRole(ROLE_MARKET_ADMIN, NEW_MARKET_ADMIN), true);

        // MARKET_ADMIN lost its role
        assertEq(thespace.hasRole(ROLE_MARKET_ADMIN, MARKET_ADMIN), false);
    }

    function testCannotTransferRoleByAttacker() public {
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSignature("RoleRequired(uint8)", ROLE_MARKET_ADMIN));
        vm.prank(ATTACKER);
        thespace.transferRole(ROLE_MARKET_ADMIN, NEW_MARKET_ADMIN);
    }

    function testCannotTransferRoleToZeroAddress() public {
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSignature("ZeroAddress()"));
        vm.prank(MARKET_ADMIN);
        thespace.transferRole(ROLE_MARKET_ADMIN, address(0));
    }

    /**
     * Renounce Role
     */
    function testRenounceRole() public {
        vm.stopPrank();

        assertEq(thespace.hasRole(ROLE_MARKET_ADMIN, MARKET_ADMIN), true);

        vm.prank(MARKET_ADMIN);
        thespace.renounceRole(ROLE_MARKET_ADMIN);

        // MARKET_ADMIN lost its role
        assertEq(thespace.hasRole(ROLE_MARKET_ADMIN, MARKET_ADMIN), false);

        // Regrant role to a new address
        vm.prank(ACL_MANAGER);
        thespace.grantRole(ROLE_MARKET_ADMIN, NEW_MARKET_ADMIN);
        assertEq(thespace.hasRole(ROLE_MARKET_ADMIN, NEW_MARKET_ADMIN), true);
    }

    function testCannotRenounceRoleByAttacker() public {
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSignature("RoleRequired(uint8)", ROLE_MARKET_ADMIN));
        vm.prank(ATTACKER);
        thespace.renounceRole(ROLE_MARKET_ADMIN);
    }

    function testCannotRenounceRoleByACLManager() public {
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        vm.prank(ACL_MANAGER);
        thespace.renounceRole(ROLE_ACL_MANAGER);
    }
}
