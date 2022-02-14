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

    // starts at 1501 since 1-1500 are reseved for Traveloggers claiming
    using Counters for Counters.Counter;
    Counters.Counter internal _tokenIdCounter = Counters.Counter(1500);

    uint256 private constant _PUBLIC_SALE_ON = 1;
    uint256 private constant _PUBLIC_SALE_OFF = 2;
    uint256 public publicSale = _PUBLIC_SALE_OFF;
    uint256 public publicSalePrice = 0;

    // contentHash to log
    mapping(bytes32 => Log) public logs;

    // tokenId to logbook
    mapping(uint256 => Book) public books;

    uint128 public basisPointsLogbookOwner = 8000;
    uint128 public basisPointsCommission = 250;

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
        Book memory book = books[tokenId_];
        book.forkPrice = amount_;
        emit SetForkPrice(tokenId_, amount_);
    }

    /// @inheritdoc ILogbook
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
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
        emit Publish(tokenId_, msg.sender, contentHash, content_);
    }

    /// @inheritdoc ILogbook
    function fork(uint256 tokenId_, bytes32 contentHash_) public payable {
        Book memory book = _fork(tokenId_, contentHash_);

        _splitRoyalty(tokenId_, book, msg.value, RoyaltyPurpose.Fork, address(0));
    }

    /// @inheritdoc ILogbook
    function forkWithCommission(
        uint256 tokenId_,
        bytes32 contentHash_,
        address commission_
    ) public payable {
        Book memory book = _fork(tokenId_, contentHash_);

        _splitRoyalty(tokenId_, book, msg.value, RoyaltyPurpose.Fork, commission_);
    }

    /// @inheritdoc ILogbook
    function donate(uint256 tokenId_) public payable {
        require(_exists(tokenId_), "ERC721: operator query for nonexistent token");

        Book memory book = books[tokenId_];
        uint256 logCount = book.contentHashes.length;

        require(logCount > 0, "Empty logbook");

        emit Donate(tokenId_, msg.sender, msg.value);

        _splitRoyalty(tokenId_, book, msg.value, RoyaltyPurpose.Donate, address(0));
    }

    /// @inheritdoc ILogbook
    function donateWithCommission(uint256 tokenId_, address commission_) public payable {
        require(_exists(tokenId_), "ERC721: operator query for nonexistent token");

        Book memory book = books[tokenId_];
        uint256 logCount = book.contentHashes.length;

        require(logCount > 0, "Empty logbook");

        emit Donate(tokenId_, msg.sender, msg.value);

        _splitRoyalty(tokenId_, book, msg.value, RoyaltyPurpose.Donate, commission_);
    }

    /// @inheritdoc ILogbook
    function setRoyaltyBPSLogbookOwner(uint128 bps_) public onlyOwner {
        require(bps_ + basisPointsCommission <= 10000, "invalid basis points");
        basisPointsLogbookOwner = bps_;
    }

    /// @inheritdoc ILogbook
    function setRoyaltyBPSCommission(uint128 bps_) public onlyOwner {
        require(bps_ + basisPointsLogbookOwner <= 10000, "invalid basis points");
        basisPointsCommission = bps_;
    }

    // function getLogbook

    // function tokenURI override
    // inline SVG

    // function _baseURI override

    /// @inheritdoc ILogbook
    function claim(address to_, uint256 logrsId_) external onlyOwner {
        require(logrsId_ >= 1 && logrsId_ <= 1500, "invalid logrs id");

        _safeMint(to_, logrsId_);
    }

    /// @inheritdoc ILogbook
    function publicSaleMint() external payable returns (uint256 tokenId) {
        require(publicSale == _PUBLIC_SALE_ON && publicSalePrice > 0, "public sale is not started");
        require(msg.value >= publicSalePrice, "value too small");

        // forward value
        address deployer = owner();
        (bool success, ) = deployer.call{value: msg.value}("");
        require(success, "failed to transfer");

        // mint
        tokenId = _mint(msg.sender);
    }

    /// @inheritdoc ILogbook
    function setPublicSalePrice(uint256 price_) external onlyOwner {
        require(price_ > 0, "zero amount");

        publicSalePrice = price_;
    }

    /// @inheritdoc ILogbook
    function togglePublicSale() external onlyOwner returns (uint256 newPublicSale) {
        newPublicSale = publicSale == _PUBLIC_SALE_ON ? _PUBLIC_SALE_OFF : _PUBLIC_SALE_ON;

        publicSale = newPublicSale;
    }

    function _mint(address to) internal returns (uint256 tokenId) {
        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
    }

    function _fork(uint256 tokenId_, bytes32 contentHash_) internal returns (Book memory book) {
        require(_exists(tokenId_), "ERC721: operator query for nonexistent token");

        book = books[tokenId_];
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

        Book memory newBook = Book({contentHashes: newContentHashes, forkPrice: 0 ether});

        books[newTokenId] = newBook;

        emit Fork(tokenId_, newTokenId, msg.sender, contentHash_, msg.value);
    }

    /**
     * @notice Split royalty payments
     * @dev No repetitive checks, please making sure the logbook is valid before calling it
     * @param purpose_ Payment purpose
     * @param book_ Logbook to be split
     * @param amount_ Total amount to split
     */
    function _splitRoyalty(
        uint256 tokenId_,
        Book memory book_,
        uint256 amount_,
        RoyaltyPurpose purpose_,
        address commission_
    ) internal {
        address logbookOwner = ERC721.ownerOf(tokenId_);
        bool isNoCommission = commission_ == address(0);

        uint256 logCount = book_.contentHashes.length;

        uint256 feesLogbookOwner = (amount_ * basisPointsLogbookOwner) / 10000;
        uint256 feesCommission = isNoCommission ? 0 : (amount_ * basisPointsCommission) / 10000;
        uint256 feesPerLogAuthor = (amount_ - feesLogbookOwner - feesCommission) / logCount;

        // -> logbook owner
        _balances[logbookOwner] += feesLogbookOwner;
        emit Pay({
            tokenId: tokenId_,
            sender: msg.sender,
            recipient: logbookOwner,
            purpose: purpose_,
            amount: feesLogbookOwner
        });

        // -> commission
        if (!isNoCommission) {
            _balances[commission_] += feesCommission;
            emit Pay({
                tokenId: tokenId_,
                sender: msg.sender,
                recipient: commission_,
                purpose: purpose_,
                amount: feesCommission
            });
        }

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
