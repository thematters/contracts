// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import {DSTest} from "ds-test/test.sol";
import {Hevm} from "./utils/Hevm.sol";
import {Snapper} from "../Snapper/Snapper.sol";

contract SnapperTest is DSTest {
    Snapper private snapper;

    Hevm constant vm = Hevm(HEVM_ADDRESS);

    address constant DEPLOYER = address(176);
    string constant CID1 = "QmYCw8HExhNnoxvc4FQQwtjK5bTZ3NKU2Np6TbNBX2ypWJ";
    string constant CID2 = "QmSmGAGMGxvKADmvYYQYHTD4BobZBJcSvZffjM6QhUC74E";

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
        snapper.takeSnapshot(1, CID1, CID2);
    }

    function testCannotTakeSnapshotNotStableBlock() public {
        vm.roll(5);
        uint256 unstableBlocknum = block.number - snapper.confirmations();

        vm.prank(DEPLOYER);
        vm.expectRevert("target contain unstable blocks");
        snapper.takeSnapshot(unstableBlocknum, CID1, CID2);
    }

    function testCannotTakeSnapshotSmallToBlocknum() public {
        vm.roll(5);
        assertEq(snapper.lastBlocknum(), 0);
        vm.prank(DEPLOYER);
        vm.expectRevert("toBlocknum must bigger than lastBlocknum");
        snapper.takeSnapshot(0, CID1, CID2);
    }

    function testTakeSnapshot() public {
        vm.roll(5);
        uint256 stableBlocknum = block.number - snapper.confirmations() - 1;

        assertEq(snapper.lastBlocknum(), 0);

        // takeSnapshot will emit Snapshot and Delta events.
        vm.expectEmit(true, false, false, true);
        emit Snapshot(stableBlocknum, CID1);
        vm.expectEmit(true, false, false, true);
        emit Delta(stableBlocknum, CID2);

        vm.prank(DEPLOYER);
        snapper.takeSnapshot(stableBlocknum, CID1, CID2);

        // takeSnapshot will update lastBlocknum
        assertEq(snapper.lastBlocknum(), stableBlocknum);
    }
}
