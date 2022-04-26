//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console2.sol";

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {Logbook} from "../Logbook/Logbook.sol";
import {ILogbook} from "../Logbook/ILogbook.sol";
import "../Logbook/NFTSVG.sol";

struct Attribute {
    string traitType;
    string value;
}

struct Metadata {
    string name;
    string description;
    // string image;
    Attribute[] attributes;
}

struct SVGTexts {
    uint32 logCount;
    uint32 transferCount;
    uint256 tokenId;
}

contract LogbookNFTSVGTest is Test {
    Logbook private logbook;

    address constant DEPLOYER = address(176);

    uint256 constant CLAIM_TOKEN_START_ID = 1;
    uint256 constant CLAIM_TOKEN_END_ID = 1500;

    function setUp() public {
        // Deploy contract with DEPLOYER
        vm.prank(DEPLOYER);
        logbook = new Logbook("Logbook", "LOGRS");

        // label addresses
        vm.label(DEPLOYER, "DEPLOYER");
    }

    function testTokenURI(
        uint8 transfers,
        uint8 logsPerTransfer,
        uint16 tokenId
    ) public {
        vm.assume(transfers < 64 && transfers > 0);
        vm.assume(logsPerTransfer < 3 && logsPerTransfer > 0);
        vm.assume(tokenId <= CLAIM_TOKEN_END_ID && tokenId >= CLAIM_TOKEN_START_ID);

        // claim logbook
        vm.prank(DEPLOYER);
        logbook.claim(DEPLOYER, tokenId);

        // append logs
        for (uint32 i = 0; i < transfers; i++) {
            // transfer to new owner
            address currentOwner = logbook.ownerOf(tokenId);
            address logbookOwner = address(uint160(i + 10000));
            assertTrue(currentOwner != logbookOwner);

            vm.prank(currentOwner);
            logbook.transferFrom(currentOwner, logbookOwner, tokenId);

            // append logs
            vm.startPrank(logbookOwner);
            for (uint32 j = 0; j < logsPerTransfer; j++) {
                logbook.publish(tokenId, Strings.toString(i * transfers));
            }
            vm.stopPrank();
        }

        string memory tokenURI = logbook.tokenURI(tokenId);

        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "scripts/logbook-metadata.js";
        inputs[2] = tokenURI;

        bytes memory res = vm.ffi(inputs);
        (Metadata memory data, SVGTexts memory texts) = abi.decode(res, (Metadata, SVGTexts));

        // name
        assertEq(data.name, string(abi.encodePacked("Logbook #", Strings.toString(tokenId))));

        // description
        assertEq(data.description, "A book that records owners' journey in Matterverse.");

        // attributes
        assertEq(data.attributes[0].traitType, "Logs");
        assertEq(data.attributes[0].value, Strings.toString(transfers * logsPerTransfer));

        // SVG texts
        assertEq(texts.logCount, transfers * logsPerTransfer);
        assertEq(texts.transferCount, transfers);
        assertEq(texts.tokenId, tokenId);
    }
}
