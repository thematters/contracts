//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ILogbook.sol";

contract Logbook is ILogbook, ERC721, Ownable {
    struct Log {
        address author;
        uint256 tokenId;
    }

    struct Book {
        bytes32[] contentHashes;
        uint256 forkPrice;
    }

    using Counters for Counters.Counter;
    Counters.Counter internal _tokenIdCounter;

    // contentHash to log
    mapping(bytes32 => Log) public logs;

    // tokenId to logbook
    mapping(uint256 => Book) public books;

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    /// @inheritdoc ILogbook
    function setTitle(uint256 tokenId_, string calldata title_) public {
        emit SetTitle(tokenId_, title_);
    }

    /// @inheritdoc ILogbook
    function setDescription(uint256 tokenId_, string calldata description_)
        public
    {
        emit SetDescription(tokenId_, description_);
    }

    /// @inheritdoc ILogbook
    function setForkPrice(uint256 tokenId_, uint256 amount_) public {
        emit SetForkPrice(tokenId_, amount_);
    }

    /// @inheritdoc ILogbook
    function multicall(bytes[] calldata data)
        external
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);

        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );
            require(success);
            results[i] = result;
        }

        return results;
    }

    /// @inheritdoc ILogbook
    function publish(uint256 tokenId_, string calldata content_) public {
        bytes32 contentHash = keccak256(abi.encodePacked(content_));
        emit Publish(tokenId_, msg.sender, contentHash, content_);
    }

    /// @inheritdoc ILogbook
    // function fork

    /// @inheritdoc ILogbook
    // function donate

    /// @inheritdoc ILogbook
    // function getLogbook

    /// @inheritdoc ILogbook
    // function tokenURI override
    // Base64:SVG?

    /// @inheritdoc ILogbook
    // function _baseURI override

    /// @inheritdoc ILogbook
    // function _mintLogbook
    // - copy contentHashes

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
}
