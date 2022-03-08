// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import {DSTest} from "ds-test/test.sol";
import {Hevm} from "./utils/Hevm.sol";
import {Snapper} from "../Snapper/Snapper.sol";

contract SnapperTest is DSTest {
    Snapper private snapper;

    Hevm constant vm = Hevm(HEVM_ADDRESS);

    address constant DEPLOYER = address(176);

    event Snapshot(uint256 indexed blocknum, string cid);
    event Delta(uint256 indexed blocknum, string cid);

    function setUp() public {
        vm.prank(DEPLOYER);
        snapper = new Snapper(2);
    }

    function testCannotSetConfirmationsByNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        snapper.setConfirmations(5);
    }

    function testSetConfirmations(uint256 confirmations_) public {
        vm.prank(DEPLOYER);
        snapper.setConfirmations(confirmations_);
        assertEq(snapper.confirmations(), confirmations_);
    }

    function testCannotTakeSnapshotByNotOwner() public {
        vm.roll(5);
        vm.expectRevert("Ownable: caller is not the owner");
        snapper.takeSnapshot(1, "cid1", "cid2");
    }

    function testCannotTakeSnapshotNotStableBlock() public {
        vm.roll(5);
        uint unstableBlocknum = block.number - snapper.confirmations() + 1;

        vm.prank(DEPLOYER);
        vm.expectRevert("target contain unstable blocks");
        snapper.takeSnapshot(unstableBlocknum, "cid1", "cid2");
    }

    function testCannotTakeSnapshotSmallToBlocknum() public {
        vm.roll(5);
        assertEq(snapper.lastBlocknum(), 0);
        vm.prank(DEPLOYER);
        vm.expectRevert("toBlocknum must bigger than lastBlocknum");
        snapper.takeSnapshot(0, "cid1", "cid2");
    }

    function testTakeSnapshot() public {
        vm.roll(5);
        uint stableBlocknum = block.number - snapper.confirmations();

        assertEq(snapper.lastBlocknum(), 0);

        // takeSnapshot will emit Snapshot and Delta events.
        vm.expectEmit(true, false, false, true);
        emit Snapshot(stableBlocknum, "cid1");
        vm.expectEmit(true, false, false, true);
        emit Delta(stableBlocknum, "cid2");

        vm.prank(DEPLOYER);
        snapper.takeSnapshot(stableBlocknum, "cid1", "cid2");

        // takeSnapshot will update lastBlocknum
        assertEq(snapper.lastBlocknum(), stableBlocknum);
    }
}
