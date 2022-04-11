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

    event Snapshot(uint256 indexed block, string cid);
    event Delta(uint256 indexed block, string cid);

    function setUp() public {
        vm.prank(DEPLOYER);
        snapper = new Snapper(2);
    }

    function testCannotSetConfirmationsByNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        snapper.setSafeConfirmations(5);
    }

    function testSetConfirmations(uint256 safeConfirmations_) public {
        vm.prank(DEPLOYER);
        snapper.setSafeConfirmations(safeConfirmations_);
        assertEq(snapper.safeConfirmations(), safeConfirmations_);
    }

    function testCannotTakeSnapshotByNotOwner() public {
        vm.roll(5);
        vm.expectRevert("Ownable: caller is not the owner");
        snapper.takeSnapshot(1, 1, CID1, CID2);
    }

    function testCannotTakeSnapshotNotStableBlock() public {
        vm.roll(5);
        uint256 unstableBlock = block.number + 2 - snapper.safeConfirmations();

        vm.prank(DEPLOYER);
        vm.expectRevert("target contain unstable blocks");
        snapper.takeSnapshot(1, unstableBlock, CID1, CID2);

        vm.prank(DEPLOYER);
        snapper.takeSnapshot(1, unstableBlock - 1, CID1, CID2);
    }

    function testCannotTakeSnapshotSmallerToBlock() public {
        vm.roll(5);
        vm.prank(DEPLOYER);
        vm.expectRevert("toBlock must be greater than or equal to fromBlock");
        snapper.takeSnapshot(2, 1, CID1, CID2);
        vm.prank(DEPLOYER);
        snapper.takeSnapshot(1, 1, CID1, CID2);
        assertEq(snapper.lastToBlock(), 1);
    }

    function testCannotTakeSnapshotSmallFromBlock() public {
        vm.roll(5);
        assertEq(snapper.lastToBlock(), 0);
        vm.prank(DEPLOYER);
        snapper.takeSnapshot(1, 1, CID1, CID2);
        assertEq(snapper.lastToBlock(), 1);

        vm.prank(DEPLOYER);
        vm.expectRevert("fromBlock must be lastToBlock + 1");
        snapper.takeSnapshot(1, 2, CID1, CID2);

        vm.prank(DEPLOYER);
        snapper.takeSnapshot(2, 2, CID1, CID2);
        assertEq(snapper.lastToBlock(), 2);
    }

    function testTakeSnapshot() public {
        vm.roll(5);
        uint256 stableBlock = block.number - snapper.safeConfirmations();

        assertEq(snapper.lastToBlock(), 0);
        assertEq(snapper.latestEventBlock(), 0);

        // takeSnapshot will emit Snapshot and Delta events.
        vm.expectEmit(true, false, false, true);
        emit Snapshot(stableBlock, CID1);
        vm.expectEmit(true, false, false, true);
        emit Delta(stableBlock, CID2);

        vm.prank(DEPLOYER);
        snapper.takeSnapshot(1, stableBlock, CID1, CID2);

        // takeSnapshot will update lastToBlock, latestEventBlock
        assertEq(snapper.lastToBlock(), stableBlock);
        assertEq(snapper.latestEventBlock(), block.number);
    }
}
