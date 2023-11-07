//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./IBillboardRegistry.sol";

contract BillboardRegistry is IBillboardRegistry, ERC721 {
    using Counters for Counters.Counter;

    Counters.Counter private tokenIds;

    bool public isOpened = false;

    address public admin;

    address public operator;

    mapping(uint256 => Board) public boards;

    constructor(
        address admin_,
        address operator_,
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {
        admin = admin_;
        operator = operator_;
    }

    //////////////////////////////
    /// Modifier
    //////////////////////////////

    modifier isValidAddress(address value_) {
        if (value_ == address(0)) {
            revert InvalidAddress();
        }
        _;
    }

    modifier isValidBoard(uint256 tokenId_) {
        uint256 latestId = tokenIds.current();

        if (tokenId_ < 1 || tokenId_ > latestId) {
            revert InvalidBoardId();
        }
        if (!_exists(tokenId_)) {
            revert BoardNotFound();
        }
        _;
    }

    modifier isBoardOwner(uint256 tokenId_, address value_) {
        if (value_ != boards[tokenId_].owner) {
            revert Unauthorized("board owner");
        }
        _;
    }

    modifier isBoardTenant(uint256 tokenId_, address value_) {
        if (value_ != _ownerOf(tokenId_)) {
            revert Unauthorized("board tenant");
        }
        _;
    }

    modifier isAdmin(address value_) {
        if (admin == address(0)) {
            revert AdminNotFound();
        }
        if (value_ == address(0)) {
            revert InvalidAddress();
        }
        if (value_ != admin) {
            revert Unauthorized("admin");
        }
        _;
    }

    modifier isFromOperator() {
        if (operator == address(0)) {
            revert OperatorNotFound();
        }
        if (msg.sender == address(0)) {
            revert InvalidAddress();
        }
        if (msg.sender != operator) {
            revert Unauthorized("operator");
        }
        _;
    }

    /// @inheritdoc IBillboardRegistry
    function setIsOpened(bool value_, address sender_) external isAdmin(sender_) isFromOperator {
        isOpened = value_;
    }

    /// @inheritdoc IBillboardRegistry
    function mint(address to_, address sender_) external isValidAddress(to_) isFromOperator returns (uint256 tokenId) {
        if (isOpened == false && sender_ != admin) {
            revert Unauthorized("minter");
        }

        tokenIds.increment();
        uint256 newBoardId = tokenIds.current();

        _safeMint(to_, newBoardId);

        Board memory newBoard = Board({
            owner: to_,
            tenant: to_,
            lastHighestBidPrice: 0,
            name: "",
            description: "",
            contentURI: "",
            redirectURI: "",
            location: ""
        });
        boards[newBoardId] = newBoard;

        emit Mint(newBoardId, to_);

        return newBoardId;
    }

    /// @inheritdoc IBillboardRegistry
    function getBoard(uint256 tokenId_) external view isValidBoard(tokenId_) returns (Board memory board) {
        return boards[tokenId_];
    }

    /// @inheritdoc IBillboardRegistry
    function setBoardName(
        uint256 tokenId_,
        string memory name_,
        address sender_
    ) external isValidBoard(tokenId_) isBoardOwner(tokenId_, sender_) {
        boards[tokenId_].name = name_;
    }

    /// @inheritdoc IBillboardRegistry
    function setBoardDescription(
        uint256 tokenId_,
        string memory description_,
        address sender_
    ) external isValidBoard(tokenId_) isBoardOwner(tokenId_, sender_) {
        boards[tokenId_].description = description_;
    }

    /// @inheritdoc IBillboardRegistry
    function setBoardLocation(
        uint256 tokenId_,
        string memory location_,
        address sender_
    ) external isValidBoard(tokenId_) isBoardOwner(tokenId_, sender_) {
        boards[tokenId_].location = location_;
    }

    /// @inheritdoc IBillboardRegistry
    function setBoardContentURI(
        uint256 tokenId_,
        string memory uri_,
        address sender_
    ) external isValidBoard(tokenId_) isBoardTenant(tokenId_, sender_) {
        boards[tokenId_].contentURI = uri_;
    }

    /// @inheritdoc IBillboardRegistry
    function setBoardRedirectURI(
        uint256 tokenId_,
        string memory redirectURI_,
        address sender_
    ) external isValidBoard(tokenId_) isBoardTenant(tokenId_, sender_) {
        boards[tokenId_].redirectURI = redirectURI_;
    }

    /// @inheritdoc IBillboardRegistry
    function setBoardLastHighestBidPrice(uint256 tokenId_, uint256 price_)
        external
        isValidBoard(tokenId_)
        isFromOperator
    {
        boards[tokenId_].lastHighestBidPrice = price_;
    }

    //////////////////////////////
    /// ERC721 Overrides
    //////////////////////////////

    /**
     * @notice See {IERC721-tokenURI}.
     */
    function tokenURI(uint256 tokenId_)
        public
        view
        override(ERC721)
        isValidBoard(tokenId_)
        returns (string memory uri)
    {
        return boards[tokenId_].contentURI;
    }

    /**
     * @notice See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner_, address operator_) public view override(ERC721, IERC721) returns (bool) {
        if (operator_ == operator) {
            return true;
        }

        return super.isApprovedForAll(owner_, operator_);
    }

    /**
     * @notice See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public override(ERC721, IERC721) isValidBoard(tokenId_) {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    /**
     * @notice See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public override(ERC721, IERC721) isValidAddress(from_) isValidAddress(to_) isValidBoard(tokenId_) {
        if (!_isApprovedOrOwner(msg.sender, tokenId_)) {
            revert Unauthorized("not owner nor approved");
        }
        _safeTransfer(from_, to_, tokenId_, data_);
        boards[tokenId_].tenant = to_;
    }
}
