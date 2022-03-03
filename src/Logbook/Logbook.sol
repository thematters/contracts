//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./ILogbook.sol";
import "./Royalty.sol";

contract Logbook is ERC721, ERC721Burnable, Ownable, ILogbook, Royalty {
    // starts at 1501 since 1-1500 are reseved for Traveloggers claiming
    using Counters for Counters.Counter;
    Counters.Counter internal _tokenIdCounter = Counters.Counter(1500);

    uint256 private constant _ROYALTY_BPS_LOGBOOK_OWNER = 8000;
    uint256 private constant _PUBLIC_SALE_ON = 1;
    uint256 private constant _PUBLIC_SALE_OFF = 2;
    uint256 public publicSale = _PUBLIC_SALE_OFF;
    uint256 public publicSalePrice;

    struct Log {
        address author;
        uint256 tokenId;
    }

    struct Book {
        // token id
        uint256 from;
        // end position of a range of logs
        uint256 endAt;
        // total number of logs
        uint256 logCount;
        uint256 forkPrice;
        uint256 createdAt;
        bytes32[] contentHashes;
    }

    // contentHash to log
    mapping(bytes32 => Log) public logs;

    // tokenId to logbook
    mapping(uint256 => Book) public books;

    /**
     * @dev Throws if called by any account other than the logbook owner.
     */
    modifier onlyLogbookOwner(uint256 tokenId_) {
        require(_isApprovedOrOwner(msg.sender, tokenId_), "caller is not owner nor approved");
        _;
    }

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    /// @inheritdoc ILogbook
    function setTitle(uint256 tokenId_, string calldata title_) public onlyLogbookOwner(tokenId_) {
        emit SetTitle(tokenId_, title_);
    }

    /// @inheritdoc ILogbook
    function setDescription(uint256 tokenId_, string calldata description_) public onlyLogbookOwner(tokenId_) {
        emit SetDescription(tokenId_, description_);
    }

    /// @inheritdoc ILogbook
    function setForkPrice(uint256 tokenId_, uint256 amount_) public onlyLogbookOwner(tokenId_) {
        books[tokenId_].forkPrice = amount_;
        emit SetForkPrice(tokenId_, amount_);
    }

    /// @inheritdoc ILogbook
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results) {
        results = new bytes[](data.length);

        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            require(success);
            results[i] = result;
        }

        return results;
    }

    /// @inheritdoc ILogbook
    function publish(uint256 tokenId_, string calldata content_) public onlyLogbookOwner(tokenId_) {
        bytes32 contentHash = keccak256(abi.encodePacked(content_));

        // log
        Log memory log = logs[contentHash];
        if (log.author == address(0)) {
            logs[contentHash] = Log(msg.sender, tokenId_);
            emit Content(msg.sender, contentHash, content_);
        }

        // logbook
        books[tokenId_].contentHashes.push(contentHash);
        books[tokenId_].logCount++;
        emit Publish(tokenId_, contentHash);
    }

    /// @inheritdoc ILogbook
    function fork(uint256 tokenId_, uint256 end_) public payable returns (uint256 tokenId) {
        (Book memory book, uint256 newTokenId) = _fork(tokenId_, end_);
        tokenId = newTokenId;

        if (msg.value > 0) {
            _splitRoyalty(tokenId_, book, msg.value, RoyaltyPurpose.Fork, address(0), 0);
        }
    }

    /// @inheritdoc ILogbook
    function forkWithCommission(
        uint256 tokenId_,
        uint256 end_,
        address commission_,
        uint256 commissionBPS_
    ) public payable returns (uint256 tokenId) {
        require(commissionBPS_ <= 10000 - _ROYALTY_BPS_LOGBOOK_OWNER, "invalid BPS");

        (Book memory book, uint256 newTokenId) = _fork(tokenId_, end_);
        tokenId = newTokenId;

        if (msg.value > 0) {
            _splitRoyalty(tokenId_, book, msg.value, RoyaltyPurpose.Fork, commission_, commissionBPS_);
        }
    }

    /// @inheritdoc ILogbook
    function donate(uint256 tokenId_) public payable {
        require(msg.value > 0, "zero value");
        require(_exists(tokenId_), "ERC721: operator query for nonexistent token");

        Book memory book = books[tokenId_];
        _splitRoyalty(tokenId_, book, msg.value, RoyaltyPurpose.Donate, address(0), 0);

        emit Donate(tokenId_, msg.sender, msg.value);
    }

    /// @inheritdoc ILogbook
    function donateWithCommission(
        uint256 tokenId_,
        address commission_,
        uint256 commissionBPS_
    ) public payable {
        require(msg.value > 0, "zero value");
        require(_exists(tokenId_), "ERC721: operator query for nonexistent token");
        require(commissionBPS_ <= 10000 - _ROYALTY_BPS_LOGBOOK_OWNER, "invalid BPS");

        Book memory book = books[tokenId_];
        _splitRoyalty(tokenId_, book, msg.value, RoyaltyPurpose.Donate, commission_, commissionBPS_);

        emit Donate(tokenId_, msg.sender, msg.value);
    }

    /// @inheritdoc ILogbook
    function getLogbook(uint256 tokenId_)
        external
        view
        returns (
            uint256 forkPrice,
            bytes32[] memory contentHashes,
            address[] memory authors
        )
    {
        Book memory book = books[tokenId_];

        forkPrice = book.forkPrice;
        contentHashes = _logs(tokenId_);
        authors = new address[](contentHashes.length);
        for (uint256 i = 0; i < contentHashes.length; i++) {
            bytes32 contentHash = contentHashes[i];
            authors[i] = logs[contentHash].author;
        }
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        require(_exists(tokenId_), "ERC721: operator query for nonexistent token");

        Book memory book = books[tokenId_];

        string memory tokenName = string(abi.encodePacked("Logbook #", _toString(tokenId_)));
        string memory description = string(
            abi.encodePacked(
                "Using Logbook to write down your thoughts, stories or anything you liked to share. Transfer your thoughts to who you want to invite them to co-create."
            )
        );
        string memory attributes = string(abi.encodePacked('{"trait_type": "Logs","value":', book.logCount, "}"));
        string memory image = Base64.encode(bytes(_generateSVGofTokenById(tokenId_)));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        tokenName,
                        '", "description": "',
                        description,
                        '", "attributes": [',
                        attributes,
                        '], "image": "data:image/svg+xml;base64,',
                        image,
                        '"}'
                    )
                )
            )
        );

        string memory output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
    }

    /// @inheritdoc ILogbook
    function claim(address to_, uint256 logrsId_) external onlyOwner {
        require(logrsId_ >= 1 && logrsId_ <= 1500, "invalid logrs id");

        _safeMint(to_, logrsId_);
    }

    /// @inheritdoc ILogbook
    function publicSaleMint() external payable returns (uint256 tokenId) {
        require(publicSale == _PUBLIC_SALE_ON && publicSalePrice > 0, "not started");
        require(msg.value >= publicSalePrice, "value too small");

        // forward value
        address deployer = owner();
        (bool success, ) = deployer.call{value: msg.value}("");
        require(success, "transfer failed");

        // mint
        tokenId = _mint(msg.sender);
    }

    /// @inheritdoc ILogbook
    function setPublicSalePrice(uint256 price_) external onlyOwner {
        require(price_ > 0, "zero value");

        publicSalePrice = price_;
    }

    /// @inheritdoc ILogbook
    function turnOnPublicSale() external onlyOwner {
        publicSale = _PUBLIC_SALE_ON;
    }

    /// @inheritdoc ILogbook
    function turnOffPublicSale() external onlyOwner {
        publicSale = _PUBLIC_SALE_OFF;
    }

    /**
     * @notice Get logs of a book
     * @param tokenId_ Logbook token id
     */
    function _logs(uint256 tokenId_) internal view returns (bytes32[] memory contentHashes) {
        Book memory book = books[tokenId_];

        contentHashes = new bytes32[](book.logCount);

        // copy from current & parents
        uint256 index = 0;
        bool hasParent = true;

        while (hasParent) {
            bytes32[] memory parentContentHashes = book.contentHashes;
            uint256 parentLogCount = parentContentHashes.length;

            for (uint256 i = 0; i < parentLogCount; i++) {
                contentHashes[index] = parentContentHashes[i];
                index++;
            }

            if (book.from == 0) {
                hasParent = false;
            }

            book = books[book.from];
        }
    }

    function _mint(address to) internal returns (uint256 tokenId) {
        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
    }

    function _fork(uint256 tokenId_, uint256 end_) internal returns (Book memory book, uint256 newTokenId) {
        require(_exists(tokenId_), "ERC721: operator query for nonexistent token");

        book = books[tokenId_];
        uint256 logCount = book.logCount;

        require(logCount > 0, "no content");
        require(logCount >= end_, "invalid end_");
        require(msg.value >= book.forkPrice, "value too small");

        // mint new logbook
        newTokenId = _mint(msg.sender);

        bytes32[] memory contentHashes = new bytes32[](0);
        Book memory newBook = Book({
            from: tokenId_,
            endAt: end_,
            logCount: logCount,
            forkPrice: 0 ether,
            createdAt: block.timestamp,
            contentHashes: contentHashes
        });

        books[newTokenId] = newBook;

        emit Fork(tokenId_, newTokenId, msg.sender, end_, msg.value);
    }

    /**
     * @notice Split royalty payments
     * @dev No repetitive checks, please make sure all arguments are valid
     * @param tokenId_ Logbook token id
     * @param book_ Logbook to be split royalty
     * @param amount_ Total amount to split royalty
     * @param purpose_ Payment purpose
     * @param commission_ commission_ Address (frontend operator) to earn commission
     * @param commissionBPS_ Basis points of the commission
     */
    function _splitRoyalty(
        uint256 tokenId_,
        Book memory book_,
        uint256 amount_,
        RoyaltyPurpose purpose_,
        address commission_,
        uint256 commissionBPS_
    ) internal {
        uint256 feesCommission;
        uint256 feesLogbookOwner;
        uint256 feesPerLogAuthor;

        bool isNoCommission = commission_ == address(0) || commissionBPS_ == 0;
        if (!isNoCommission) {
            feesCommission = (amount_ * commissionBPS_) / 10000;
        }

        uint256 logCount = book_.logCount;
        if (logCount <= 0) {
            feesLogbookOwner = amount_ - feesCommission;
        } else {
            feesLogbookOwner = (amount_ * _ROYALTY_BPS_LOGBOOK_OWNER) / 10000;
            feesPerLogAuthor = (amount_ - feesLogbookOwner - feesCommission) / logCount;
        }

        // -> logbook owner
        address logbookOwner = ERC721.ownerOf(tokenId_);
        _balances[logbookOwner] += feesLogbookOwner;
        emit Pay({
            tokenId: tokenId_,
            sender: msg.sender,
            recipient: logbookOwner,
            amount: feesLogbookOwner,
            purpose: purpose_
        });

        // -> commission
        if (!isNoCommission) {
            _balances[commission_] += feesCommission;
            emit Pay({
                tokenId: tokenId_,
                sender: msg.sender,
                recipient: commission_,
                amount: feesCommission,
                purpose: purpose_
            });
        }

        // -> logs' authors
        if (logCount > 0) {
            for (uint256 i = 0; i < logCount; i++) {
                Log memory log = logs[book_.contentHashes[i]];
                _balances[log.author] += feesPerLogAuthor;
                emit Pay({
                    tokenId: tokenId_,
                    sender: msg.sender,
                    recipient: log.author,
                    amount: feesPerLogAuthor,
                    purpose: purpose_
                });
            }
        }
    }

    /**
     * @notice Generate SVG image by token id
     * @param tokenId_ Logbook token id
     */
    function _generateSVGofTokenById(uint256 tokenId_) internal pure returns (string memory svg) {
        return string(abi.encodePacked("<svg>", _toString(tokenId_), "</svg>"));
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
