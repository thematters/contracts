//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ILogbook.sol";
import "./Royalty.sol";

contract Logbook is ERC721, Ownable, ILogbook, Royalty {
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

    uint128 public basisPointsLogbookOwner = 8000;
    uint128 public basisPointsContract = 250;

    /**
     * @dev Throws if called by any account other than the logbook owner.
     */
    modifier onlyLogbookOwner(uint256 tokenId_) {
        require(
            _isApprovedOrOwner(msg.sender, tokenId_),
            "caller is not owner nor approved"
        );
        _;
    }

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    /// @inheritdoc ILogbook
    function setTitle(uint256 tokenId_, string calldata title_)
        public
        onlyLogbookOwner(tokenId_)
    {
        emit SetTitle(tokenId_, title_);
    }

    /// @inheritdoc ILogbook
    function setDescription(uint256 tokenId_, string calldata description_)
        public
        onlyLogbookOwner(tokenId_)
    {
        emit SetDescription(tokenId_, description_);
    }

    /// @inheritdoc ILogbook
    function setForkPrice(uint256 tokenId_, uint256 amount_)
        public
        onlyLogbookOwner(tokenId_)
    {
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
    function publish(uint256 tokenId_, string calldata content_)
        public
        onlyLogbookOwner(tokenId_)
    {
        bytes32 contentHash = keccak256(abi.encodePacked(content_));
        emit Publish(tokenId_, msg.sender, contentHash, content_);
    }

    /// @inheritdoc ILogbook
    function fork(uint256 tokenId_, bytes32 contentHash_) public payable {
        require(
            _exists(tokenId_),
            "ERC721: operator query for nonexistent token"
        );

        Book memory book = books[tokenId_];
        uint256 logCount = book.contentHashes.length;

        require(logCount > 0, "No content to fork");
        require(msg.value >= book.forkPrice, "Not enough value to fork");

        // mint new logbook
        uint256 newTokenId = _mint(msg.sender);

        // copy content hashes to the new logbook
        bytes32[] memory newContentHashes;

        for (uint256 i = 0; i < logCount; i++) {
            bytes32 contentHash = book.contentHashes[i];
            newContentHashes[i] = contentHash;

            if (contentHash == contentHash_) {
                break;
            }
        }

        Book memory newBook = Book({
            contentHashes: newContentHashes,
            forkPrice: 0 ether
        });

        books[newTokenId] = newBook;

        emit Fork(tokenId_, newTokenId, msg.sender, contentHash_, msg.value);

        // split royalty payments
        _splitRoyalty(tokenId_, book, msg.value, RoyaltyPurpose.Fork);
    }

    /// @inheritdoc ILogbook
    function donate(uint256 tokenId_) public payable {
        require(
            _exists(tokenId_),
            "ERC721: operator query for nonexistent token"
        );

        Book memory book = books[tokenId_];
        uint256 logCount = book.contentHashes.length;

        require(logCount > 0, "Empty logbook");

        emit Donate(tokenId_, msg.sender, msg.value);

        // split royalty payments
        _splitRoyalty(tokenId_, book, msg.value, RoyaltyPurpose.Donate);
    }

    /// @inheritdoc ILogbook
    function setRoyaltyBPSLogbookOwner(uint128 bps_) public onlyOwner {
        require(bps_ + basisPointsContract <= 10000, "invalid basis points");
        basisPointsLogbookOwner = bps_;
    }

    /// @inheritdoc ILogbook
    function setRoyaltyBPSContract(uint128 bps_) public onlyOwner {
        require(
            bps_ + basisPointsLogbookOwner <= 10000,
            "invalid basis points"
        );
        basisPointsContract = bps_;
    }

    // function getLogbook

    // function tokenURI override
    // Base64:SVG?

    // function _baseURI override

    // function mint(address to) public onlyOwner returns (uint256 tokenId) {
    //     _tokenIdCounter.increment();
    //     tokenId = _tokenIdCounter.current();
    //     _safeMint(to, tokenId);
    // }

    function _mint(address to) internal returns (uint256 tokenId) {
        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
    }

    /**
     * @notice Split royalty payments
     * @dev No repetitive checks, please making sure the logbook is valid before calling it
     * @param purpose_ payment purpose
     * @param book_ logbook to be split
     * @param amount_ total amount to split
     */
    function _splitRoyalty(
        uint256 tokenId_,
        Book memory book_,
        uint256 amount_,
        RoyaltyPurpose purpose_
    ) internal {
        address logbookOwner = ERC721.ownerOf(tokenId_);

        uint256 logCount = book_.contentHashes.length;

        uint256 feesLogbookOwner = (amount_ * basisPointsLogbookOwner) / 10000;
        uint256 feesContract = (amount_ * basisPointsContract) / 10000;
        uint256 feesPerLogAuthor = (amount_ - feesLogbookOwner - feesContract) /
            logCount;

        // -> logbook owner
        _balances[logbookOwner] += feesLogbookOwner;
        emit Pay({
            tokenId: tokenId_,
            sender: msg.sender,
            recipient: logbookOwner,
            purpose: purpose_,
            amount: feesLogbookOwner
        });

        // -> contract
        _balances[address(this)] += feesContract;
        emit Pay({
            tokenId: tokenId_,
            sender: msg.sender,
            recipient: address(this),
            purpose: purpose_,
            amount: feesContract
        });

        // -> logs' authors
        for (uint256 i = 0; i < logCount; i++) {
            bytes32 contentHash = book_.contentHashes[i];
            Log memory log = logs[contentHash];
            _balances[log.author] += feesPerLogAuthor;
            emit Pay({
                tokenId: tokenId_,
                sender: msg.sender,
                recipient: log.author,
                purpose: purpose_,
                amount: feesPerLogAuthor
            });
        }
    }
}
