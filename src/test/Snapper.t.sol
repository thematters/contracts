// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console2.sol";

import {Snapper} from "../Snapper/Snapper.sol";

contract SnapperTest is Test {
    Snapper private snapper;

    address constant DEPLOYER = address(176);
    string constant CID0 = "QmYCw8HExhNnoxvc4FQQwtjK5bTZ3NKU2Np6TbNBX2ypW0";
    string constant CID1 = "QmYCw8HExhNnoxvc4FQQwtjK5bTZ3NKU2Np6TbNBX2ypWJ";
    string constant CID2 = "QmSmGAGMGxvKADmvYYQYHTD4BobZBJcSvZffjM6QhUC74E";

    event Snapshot(uint256 indexed regionId, uint256 indexed block, string cid);
    event Delta(uint256 indexed regionId, uint256 indexed block, string cid);

    function setUp() public {
        vm.roll(2);

        vm.prank(DEPLOYER);
        snapper = new Snapper();

        vm.prank(DEPLOYER);
        snapper.initRegion(0, 1, CID0);
    }

    function testCannotInitRegionByNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        snapper.initRegion(1, 1, CID0);
    }

    function testCannotReInitRegion() public {
        vm.prank(DEPLOYER);
        vm.expectRevert(abi.encodeWithSignature("CannotBeReInitialized(uint256)", 0));
        snapper.initRegion(0, 1, CID0);
    }

    function testInitRegion(uint256 regionId) public {
        vm.assume(regionId > 0);

        Snapper.SnapshotInfo memory ss1 = snapper.latestSnapshotInfo(regionId);
        assertEq(ss1.block, 0);
        assertEq(ss1.cid, "");

        // expect emit `Snapshot` Event
        vm.expectEmit(true, true, false, true);
        emit Snapshot(regionId, 1, CID0);

        vm.prank(DEPLOYER);
        snapper.initRegion(regionId, 1, CID0);

        // expect update _latestSnapshots
        Snapper.SnapshotInfo memory ss2 = snapper.latestSnapshotInfo(regionId);
        assertEq(ss2.block, 1);
        assertEq(ss2.cid, CID0);
    }

    function testCannotTakeSnapshotByNotOwner() public {
        vm.roll(5);
        vm.expectRevert("Ownable: caller is not the owner");
        snapper.takeSnapshot(0, 1, 2, CID1, CID2);
    }

    function testCannotTakeSnapshotBeforeInit() public {
        vm.roll(5);
        vm.prank(DEPLOYER);
        vm.expectRevert(abi.encodeWithSignature("InvalidLastSnapshotBlock(uint256,uint256,uint256)", 1, 0, 0));
        snapper.takeSnapshot(1, 0, 2, CID1, CID2);
    }

    function testCannotTakeSnapshotWrongLastBlock() public {
        vm.roll(5);

        vm.prank(DEPLOYER);
        vm.expectRevert(abi.encodeWithSignature("InvalidLastSnapshotBlock(uint256,uint256,uint256)", 0, 0, 1));
        snapper.takeSnapshot(0, 0, 2, CID1, CID2);

        vm.prank(DEPLOYER);
        vm.expectRevert(abi.encodeWithSignature("InvalidLastSnapshotBlock(uint256,uint256,uint256)", 0, 3, 1));
        snapper.takeSnapshot(0, 3, 4, CID1, CID2);

        vm.prank(DEPLOYER);
        snapper.takeSnapshot(0, 1, 2, CID1, CID2);
    }

    function testCannotTakeSnapshotWrongSnapshotBlock() public {
        vm.roll(5);

        vm.prank(DEPLOYER);
        vm.expectRevert(abi.encodeWithSignature("InvalidTargetSnapshotBlock(uint256,uint256,uint256)", 0, 1, 1));
        snapper.takeSnapshot(0, 1, 1, CID1, CID2);

        vm.prank(DEPLOYER);
        vm.expectRevert(abi.encodeWithSignature("InvalidTargetSnapshotBlock(uint256,uint256,uint256)", 0, 0, 1));
        snapper.takeSnapshot(0, 1, 0, CID1, CID2);
    }

    function testTakeSnapshot() public {
        vm.roll(5);

        uint256 snapshotBlock = 3;

        Snapper.SnapshotInfo memory ss1 = snapper.latestSnapshotInfo();
        assertEq(ss1.block, 1);
        assertEq(ss1.cid, CID0);

        // expect emit `Snapshot` and `Delta` events.
        vm.expectEmit(true, true, false, true);
        emit Snapshot(0, snapshotBlock, CID1);
        vm.expectEmit(true, true, false, true);
        emit Delta(0, snapshotBlock, CID2);

        vm.prank(DEPLOYER);
        snapper.takeSnapshot(0, 1, snapshotBlock, CID1, CID2);

        // expect update _latestSnapshots
        Snapper.SnapshotInfo memory ss2 = snapper.latestSnapshotInfo();
        assertEq(ss2.block, snapshotBlock);
        assertEq(ss2.cid, CID1);
    }
}
