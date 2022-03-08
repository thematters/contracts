// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import {DSTest} from "ds-test/test.sol";
import {Hevm} from "./utils/Hevm.sol";
import {Snapper} from "../Snapper/Snapper.sol";

contract SnapperTest is DSTest {
    Snapper private snapper;

    Hevm constant vm = Hevm(HEVM_ADDRESS);

    address constant DEPLOYER = address(176);

    function setUp() public {
        vm.prank(DEPLOYER);
        snapper = new Snapper(2);
    }

    function testCannotSetConfirmations() public {
        vm.expectRevert("Ownable: caller is not the owner");
        snapper.setConfirmations(5);
    }

    function testSetConfirmations(uint256 confirmations_) public {
        vm.prank(DEPLOYER);
        snapper.setConfirmations(confirmations_);
        assertEq(snapper.confirmations(), confirmations_);
    }
}
