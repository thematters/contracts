//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console2.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {USDT} from "./USDT.sol";
import {Curation as CurationContract} from "../../Curation/Curation.sol";

contract CurationTest is Test {
    CurationContract internal curation;
    USDT internal usdt;

    event Curation(address indexed curator, address indexed creator, string indexed uri, IERC20 token, uint256 amount);

    event Curation(address indexed curator, address indexed creator, string indexed uri, uint256 amount);

    address constant DEPLOYER = address(176);
    address constant CREATOR = address(177);
    address constant CURATOR = address(178);
    address constant ATTACKER = address(179);
    address constant APPROVED = address(180);

    function setUp() public {
        // label addresses
        vm.label(DEPLOYER, "DEPLOYER");
        vm.label(CREATOR, "CREATOR");
        vm.label(CURATOR, "CURATOR");
        vm.label(ATTACKER, "ATTACKER");
        vm.label(APPROVED, "APPROVED");

        // deploy Curation contract
        vm.prank(DEPLOYER);
        curation = new CurationContract();

        // deploy ERC-20 token
        usdt = new USDT(CURATOR, 1000);
        assertEq(usdt.balanceOf(CURATOR), 1000 * (10**uint256(usdt.decimals())));
        assertEq(usdt.balanceOf(CREATOR), 0);
        vm.prank(CURATOR);
        usdt.approve(address(curation), type(uint256).max);

        // fund curator
        vm.deal(CURATOR, 100 ether);
    }

    /**
     * Curation: ERC-20 token
     */
    function testERC20Curation() public {
        uint256 amount = 10 * (10**uint256(usdt.decimals()));
        string memory uri = "ipfs://Qmaisz6NMhDB51cCvNWa1GMS7LU1pAxdF4Ld6Ft9kZEP2a";
        uint256 curatorBalance = usdt.balanceOf(CURATOR);

        vm.expectEmit(true, true, true, true);
        emit Curation(CURATOR, CREATOR, uri, usdt, amount);

        vm.prank(CURATOR);
        curation.curate(CREATOR, usdt, amount, uri);

        assertEq(usdt.balanceOf(CREATOR), amount);
        assertEq(usdt.balanceOf(CURATOR), curatorBalance - amount);
    }

    function testCannotCurateERC20IfNotApproval() public {
        uint256 amount = 10 * (10**uint256(usdt.decimals()));
        string memory uri = "ipfs://Qmaisz6NMhDB51cCvNWa1GMS7LU1pAxdF4Ld6Ft9kZEP2a";

        vm.startPrank(CURATOR);

        // revert the allowance
        usdt.approve(address(curation), 0);

        // curate
        vm.expectRevert("ERC20: insufficient allowance");
        curation.curate(CREATOR, usdt, amount, uri);

        vm.stopPrank();
    }

    function testCannotCurateERC20ZeroAddress() public {
        uint256 amount = 10 * (10**uint256(usdt.decimals()));
        string memory uri = "ipfs://Qmaisz6NMhDB51cCvNWa1GMS7LU1pAxdF4Ld6Ft9kZEP2a";

        vm.expectRevert(abi.encodeWithSignature("ZeroAddress()"));
        vm.prank(CURATOR);
        curation.curate(address(0), usdt, amount, uri);
    }

    function testCannotCurateERC20CurateZeroAmount() public {
        string memory uri = "ipfs://Qmaisz6NMhDB51cCvNWa1GMS7LU1pAxdF4Ld6Ft9kZEP2a";

        vm.expectRevert(abi.encodeWithSignature("ZeroAmount()"));
        vm.prank(CURATOR);
        curation.curate(CREATOR, usdt, 0, uri);
    }

    function testCannotCurateERC20EmptyURI() public {
        uint256 amount = 10 * (10**uint256(usdt.decimals()));
        string memory uri = "";

        vm.expectRevert(abi.encodeWithSignature("InvalidURI()"));
        vm.prank(CURATOR);
        curation.curate(CURATOR, usdt, amount, uri);
    }

    function testCannotCurateERC20SelfCuration() public {
        uint256 amount = 10 * (10**uint256(usdt.decimals()));
        string memory uri = "ipfs://Qmaisz6NMhDB51cCvNWa1GMS7LU1pAxdF4Ld6Ft9kZEP2a";

        vm.expectRevert(abi.encodeWithSignature("SelfCuration()"));
        vm.prank(CURATOR);
        curation.curate(CURATOR, usdt, amount, uri);
    }

    /**
     * Curation: Native Token
     */
    function testNativeTokenCuration() public {
        uint256 amount = 1 ether;
        string memory uri = "ipfs://Qmaisz6NMhDB51cCvNWa1GMS7LU1pAxdF4Ld6Ft9kZEP2a";
        uint256 curatorBalance = CURATOR.balance;

        vm.expectEmit(true, true, true, true);
        emit Curation(CURATOR, CREATOR, uri, amount);

        vm.prank(CURATOR);
        curation.curate{value: amount}(CREATOR, uri);

        assertEq(CREATOR.balance, amount);
        assertEq(CURATOR.balance, curatorBalance - amount);
    }

    function testCannotCurateNativeTokenZeroAddress() public {
        uint256 amount = 1 ether;
        string memory uri = "";

        vm.expectRevert(abi.encodeWithSignature("ZeroAddress()"));
        vm.prank(CURATOR);
        curation.curate{value: amount}(address(0), uri);
    }

    function testCannotCurateNativeTokenCurateZeroAmount() public {
        string memory uri = "ipfs://Qmaisz6NMhDB51cCvNWa1GMS7LU1pAxdF4Ld6Ft9kZEP2a";

        vm.expectRevert(abi.encodeWithSignature("ZeroAmount()"));
        vm.prank(CURATOR);
        curation.curate{value: 0}(CREATOR, uri);
    }

    function testCannotCurateNativeTokenSelfCuration() public {
        uint256 amount = 1 ether;
        string memory uri = "ipfs://Qmaisz6NMhDB51cCvNWa1GMS7LU1pAxdF4Ld6Ft9kZEP2a";

        vm.expectRevert(abi.encodeWithSignature("SelfCuration()"));
        vm.prank(CURATOR);
        curation.curate{value: amount}(CURATOR, uri);
    }

    function testCannotCurateNativeTokenEmptyURI() public {
        uint256 amount = 1 ether;
        string memory uri = "";

        vm.expectRevert(abi.encodeWithSignature("InvalidURI()"));
        vm.prank(CURATOR);
        curation.curate{value: amount}(CURATOR, uri);
    }
}
