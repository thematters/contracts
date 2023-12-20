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

    /// Deployer and admin could be the same one
    address constant OWNER = address(100);
    address constant ADMIN = address(101);
    address constant USER = address(102);
    address constant ATTACKER = address(200);

    function setUp() public {
        vm.startPrank(OWNER);

        // deploy
        distribution = new Distribution();
        assertEq(distribution.admin(), OWNER);

        vm.stopPrank();
    }
}
