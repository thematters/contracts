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

    // error InvalidLastSnapshotBlock(uint256 last, uint256 latest);
    // error InvalidSnapshotBlock(uint256 target, uint256 latest);

    event Snapshot(uint256 indexed block, string cid);
    event Delta(uint256 indexed block, string cid);

    function setUp() public {
        vm.roll(2);

        // emit initial Snapshot Event when creating contracts.
        // vm.expectEmit(true, false, false, true);
        // emit Snapshot(1, CID1);

        vm.prank(DEPLOYER);
        snapper = new Snapper(1, CID0);
    }

    function testCannotTakeSnapshotByNotOwner() public {
        vm.roll(5);
        vm.expectRevert("Ownable: caller is not the owner");
        snapper.takeSnapshot(1, 2, CID1, CID2);
    }

    function testCannotTakeSnapshotWrongLastBlock() public {
        vm.roll(5);

        vm.prank(DEPLOYER);
        vm.expectRevert(abi.encodeWithSignature("InvalidLastSnapshotBlock(uint256,uint256)", 0, 1));
        snapper.takeSnapshot(0, 2, CID1, CID2);

        vm.prank(DEPLOYER);
        vm.expectRevert(abi.encodeWithSignature("InvalidLastSnapshotBlock(uint256,uint256)", 3, 1));
        snapper.takeSnapshot(3, 4, CID1, CID2);

        vm.prank(DEPLOYER);
        snapper.takeSnapshot(1, 2, CID1, CID2);
    }

    function testCannotTakeSnapshotWrongSnapshotBlock() public {
        vm.roll(5);

        vm.prank(DEPLOYER);
        vm.expectRevert(abi.encodeWithSignature("InvalidSnapshotBlock(uint256,uint256)", 1, 1));
        snapper.takeSnapshot(1, 1, CID1, CID2);

        vm.prank(DEPLOYER);
        vm.expectRevert(abi.encodeWithSignature("InvalidSnapshotBlock(uint256,uint256)", 0, 1));
        snapper.takeSnapshot(1, 0, CID1, CID2);
    }

    function testTakeSnapshot() public {
        vm.roll(5);

        uint256 snapshotBlock = 3;

        (uint256 bk1, string memory cid1) = snapper.latestSnapshotInfo();
        assertEq(bk1, 1);
        assertEq(cid1, CID0);

        // takeSnapshot will emit Snapshot and Delta events.
        vm.expectEmit(true, false, false, true);
        emit Snapshot(snapshotBlock, CID1);
        vm.expectEmit(true, false, false, true);
        emit Delta(snapshotBlock, CID2);

        vm.prank(DEPLOYER);
        snapper.takeSnapshot(1, snapshotBlock, CID1, CID2);

        // takeSnapshot will update latestSnapshotInfo
        (uint256 bk2, string memory cid2) = snapper.latestSnapshotInfo();
        assertEq(bk2, snapshotBlock);
        assertEq(cid2, CID1);
    }
}
