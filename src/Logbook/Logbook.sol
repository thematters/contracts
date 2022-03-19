//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./ILogbook.sol";
import "./Royalty.sol";
import "./NFTSVG.sol";

contract Logbook is ERC721, Ownable, ILogbook, Royalty {
    uint256 private constant _ROYALTY_BPS_LOGBOOK_OWNER = 8000;
    uint256 private constant _ROYALTY_BPS_COMMISSION_MAX = 10000 - _ROYALTY_BPS_LOGBOOK_OWNER;
    uint256 private constant _PUBLIC_SALE_ON = 1;
    uint256 private constant _PUBLIC_SALE_OFF = 2;
    uint256 public publicSale = _PUBLIC_SALE_OFF;
    uint256 public publicSalePrice;

    // contentHash to log
    mapping(bytes32 => Log) public logs;

    // tokenId to logbook
    mapping(uint256 => Book) private _books;

    // starts at 1501 since 1-1500 are reseved for Traveloggers claiming
    using Counters for Counters.Counter;
    Counters.Counter internal _tokenIdCounter = Counters.Counter(1500);

    /**
     * @dev Throws if called by any account other than the logbook owner.
     */
    modifier onlyLogbookOwner(uint256 tokenId_) {
        if (!_isApprovedOrOwner(msg.sender, tokenId_)) revert Unauthorized();
        _;
    }

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    /// @inheritdoc ILogbook
    function setTitle(uint256 tokenId_, string calldata title_) external onlyLogbookOwner(tokenId_) {
        emit SetTitle(tokenId_, title_);
    }

    /// @inheritdoc ILogbook
    function setDescription(uint256 tokenId_, string calldata description_) external onlyLogbookOwner(tokenId_) {
        emit SetDescription(tokenId_, description_);
    }

    /// @inheritdoc ILogbook
    function setForkPrice(uint256 tokenId_, uint256 amount_) external onlyLogbookOwner(tokenId_) {
        _books[tokenId_].forkPrice = amount_;
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
    function publish(uint256 tokenId_, string calldata content_) external onlyLogbookOwner(tokenId_) {
        bytes32 contentHash = keccak256(abi.encodePacked(content_));

        // log
        Log memory log = logs[contentHash];
        if (log.author == address(0)) {
            logs[contentHash] = Log(msg.sender, tokenId_);
            emit Content(msg.sender, contentHash, content_);
        }

        // logbook
        _books[tokenId_].logCount++;
        _books[tokenId_].contentHashes.push(contentHash);
        emit Publish(tokenId_, contentHash);
    }

    /// @inheritdoc ILogbook
    function fork(uint256 tokenId_, uint32 endAt_) external payable returns (uint256 tokenId) {
        (Book memory book, uint256 newTokenId) = _fork(tokenId_, endAt_);
        tokenId = newTokenId;

        if (msg.value > 0) {
            address logbookOwner = ERC721.ownerOf(tokenId_);
            _splitRoyalty(tokenId_, book, logbookOwner, msg.value, RoyaltyPurpose.Fork, address(0), 0);
        }
    }

    /// @inheritdoc ILogbook
    function forkWithCommission(
        uint256 tokenId_,
        uint32 endAt_,
        address commission_,
        uint256 commissionBPS_
    ) external payable returns (uint256 tokenId) {
        if (commissionBPS_ > _ROYALTY_BPS_COMMISSION_MAX) revert InvalidBPS(0, _ROYALTY_BPS_COMMISSION_MAX);

        (Book memory book, uint256 newTokenId) = _fork(tokenId_, endAt_);
        tokenId = newTokenId;

        if (msg.value > 0) {
            address logbookOwner = ERC721.ownerOf(tokenId_);
            _splitRoyalty(tokenId_, book, logbookOwner, msg.value, RoyaltyPurpose.Fork, commission_, commissionBPS_);
        }
    }

    /// @inheritdoc ILogbook
    function donate(uint256 tokenId_) external payable {
        if (msg.value <= 0) revert ZeroAmount();
        if (!_exists(tokenId_)) revert TokenNotExists();

        Book memory book = _books[tokenId_];
        address logbookOwner = ERC721.ownerOf(tokenId_);

        _splitRoyalty(tokenId_, book, logbookOwner, msg.value, RoyaltyPurpose.Donate, address(0), 0);

        emit Donate(tokenId_, msg.sender, msg.value);
    }

    /// @inheritdoc ILogbook
    function donateWithCommission(
        uint256 tokenId_,
        address commission_,
        uint256 commissionBPS_
    ) external payable {
        if (msg.value <= 0) revert ZeroAmount();
        if (!_exists(tokenId_)) revert TokenNotExists();
        if (commissionBPS_ > _ROYALTY_BPS_COMMISSION_MAX) revert InvalidBPS(0, _ROYALTY_BPS_COMMISSION_MAX);

        Book memory book = _books[tokenId_];
        address logbookOwner = ERC721.ownerOf(tokenId_);

        _splitRoyalty(tokenId_, book, logbookOwner, msg.value, RoyaltyPurpose.Donate, commission_, commissionBPS_);

        emit Donate(tokenId_, msg.sender, msg.value);
    }

    /// @inheritdoc ILogbook
    function getLogbook(uint256 tokenId_) external view returns (Book memory book) {
        book = _books[tokenId_];
    }

    /// @inheritdoc ILogbook
    function getLogs(uint256 tokenId_)
        external
        view
        returns (bytes32[] memory contentHashes, address[] memory authors)
    {
        Book memory book = _books[tokenId_];
        uint32 logCount = book.logCount;

        contentHashes = _logs(tokenId_);
        authors = new address[](logCount);
        for (uint32 i = 0; i < logCount; i++) {
            bytes32 contentHash = contentHashes[i];
            authors[i] = logs[contentHash].author;
        }
    }

    /// @inheritdoc ILogbook
    function claim(address to_, uint256 logrsId_) external onlyOwner {
        if (logrsId_ < 1 || logrsId_ > 1500) revert InvalidTokenId(1, 1500);

        _safeMint(to_, logrsId_);

        _books[logrsId_].createdAt = uint160(block.timestamp);
    }

    /// @inheritdoc ILogbook
    function publicSaleMint() external payable returns (uint256 tokenId) {
        if (publicSale != _PUBLIC_SALE_ON) revert PublicSaleNotStarted();
        if (msg.value < publicSalePrice) revert InsufficientAmount(msg.value, publicSalePrice);

        // forward value
        address deployer = owner();
        (bool success, ) = deployer.call{value: msg.value}("");
        require(success);

        // mint
        tokenId = _mint(msg.sender);
    }

    /// @inheritdoc ILogbook
    function setPublicSalePrice(uint256 price_) external onlyOwner {
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

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        if (!_exists(tokenId_)) revert TokenNotExists();

        Book memory book = _books[tokenId_];
        uint32 logCount = book.logCount;

        string memory tokenName = string(abi.encodePacked("Logbook #", Strings.toString(tokenId_)));
        string memory description = "A book that records owners' journey in Matterverse.";
        string memory attributeLogs = string(
            abi.encodePacked('{"trait_type": "Logs","value":"', Strings.toString(logCount), '"}')
        );

        NFTSVG.SVGParams memory svgParams = NFTSVG.SVGParams({
            logCount: logCount,
            transferCount: book.transferCount,
            createdAt: book.createdAt,
            tokenId: tokenId_
        });
        string memory image = Base64.encode(bytes(NFTSVG.generateSVG(svgParams)));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        tokenName,
                        '", "description": "',
                        description,
                        '", "attributes": [',
                        attributeLogs,
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

    /**
     * @notice Get logs of a book
     * @param tokenId_ Logbook token id
     */
    function _logs(uint256 tokenId_) internal view returns (bytes32[] memory contentHashes) {
        Book memory book = _books[tokenId_];

        contentHashes = new bytes32[](book.logCount);
        uint32 index = 0;

        // copy from parents
        Book memory parent = _books[book.from];
        uint32 takes = book.endAt;
        bool hasParent = book.from == 0 ? false : true;

        while (hasParent) {
            bytes32[] memory parentContentHashes = parent.contentHashes;
            for (uint32 i = 0; i < takes; i++) {
                contentHashes[index] = parentContentHashes[i];
                index++;
            }

            if (parent.from == 0) {
                hasParent = false;
            } else {
                takes = parent.endAt;
                parent = _books[parent.from];
            }
        }

        // copy from current
        bytes32[] memory currentContentHashes = book.contentHashes;
        for (uint32 i = 0; i < currentContentHashes.length; i++) {
            contentHashes[index] = currentContentHashes[i];
            index++;
        }
    }

    function _mint(address to) internal returns (uint256 tokenId) {
        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);

        _books[tokenId].createdAt = uint160(block.timestamp);
    }

    function _fork(uint256 tokenId_, uint32 endAt_) internal returns (Book memory newBook, uint256 newTokenId) {
        if (!_exists(tokenId_)) revert TokenNotExists();

        Book memory book = _books[tokenId_];
        uint32 maxEndAt = uint32(book.contentHashes.length);
        uint32 logCount = book.logCount;

        if (logCount <= 0 || endAt_ <= 0 || maxEndAt < endAt_) revert InsufficientLogs(maxEndAt);
        if (msg.value < book.forkPrice) revert InsufficientAmount(msg.value, book.forkPrice);

        // mint new logbook
        newTokenId = _mint(msg.sender);

        bytes32[] memory contentHashes = new bytes32[](0);
        newBook = Book({
            endAt: endAt_,
            logCount: logCount - maxEndAt + endAt_,
            transferCount: 1,
            createdAt: uint160(block.timestamp),
            from: tokenId_,
            forkPrice: 0 ether,
            contentHashes: contentHashes
        });

        _books[newTokenId] = newBook;

        emit Fork(tokenId_, newTokenId, msg.sender, endAt_, msg.value);
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
        address logbookOwner_,
        uint256 amount_,
        RoyaltyPurpose purpose_,
        address commission_,
        uint256 commissionBPS_
    ) internal {
        uint32 logCount = book_.logCount;
        bytes32[] memory contentHashes = _logs(tokenId_);

        // fees calculation
        SplitRoyaltyFees memory fees;
        bool isNoCommission = commission_ == address(0) || commissionBPS_ == 0;
        if (!isNoCommission) {
            fees.commission = (amount_ * commissionBPS_) / 10000;
        }

        if (logCount <= 0) {
            fees.logbookOwner = amount_ - fees.commission;
        } else {
            fees.logbookOwner = (amount_ * _ROYALTY_BPS_LOGBOOK_OWNER) / 10000;
            fees.perLogAuthor = (amount_ - fees.logbookOwner - fees.commission) / logCount;
        }

        // split royalty
        // -> logbook owner
        _balances[logbookOwner_] += fees.logbookOwner;
        emit Pay({
            tokenId: tokenId_,
            sender: msg.sender,
            recipient: logbookOwner_,
            amount: fees.logbookOwner,
            purpose: purpose_
        });

        // -> commission
        if (!isNoCommission) {
            _balances[commission_] += fees.commission;
            emit Pay({
                tokenId: tokenId_,
                sender: msg.sender,
                recipient: commission_,
                amount: fees.commission,
                purpose: purpose_
            });
        }

        // -> logs' authors
        if (logCount > 0) {
            for (uint32 i = 0; i < logCount; i++) {
                Log memory log = logs[contentHashes[i]];
                _balances[log.author] += fees.perLogAuthor;
                emit Pay({
                    tokenId: tokenId_,
                    sender: msg.sender,
                    recipient: log.author,
                    amount: fees.perLogAuthor,
                    purpose: purpose_
                });
            }
        }
    }

    function _afterTokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal virtual override {
        super._afterTokenTransfer(from_, to_, tokenId_); // Call parent hook

        _books[tokenId_].transferCount++;

        // warm up _balances[to] to reduce gas of SSTORE on _splitRoyalty
        if (_balances[to_] == 0) {
            _balances[to_] = 1 wei;
        }
    }
}
