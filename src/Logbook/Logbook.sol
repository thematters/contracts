//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";



contract Logbook is ERC721 {
    struct Log {
        address sender;
        uint256 tokenId;
    }

    struct Book {
        uint256[] logContentHashes;
        uint256 forkPrice;
    }
    
    using Counters for Counters.Counter;
    Counters.Counter internal _tokenId;

    // logContentHash to log
    mapping(uint256 => Log) public logs;

    // tokenId to logbook
    mapping(uint256 => Book) public books;

    // function setTitle

    // function setDescription

    // function setForkPrice

    // function multicall

    // function publish

    // function fork

    // function donate

    // function getLogbook

    // function _mintLogbook

}
