//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console2.sol";

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {Logbook} from "../Logbook/Logbook.sol";
import {ILogbook} from "../Logbook/ILogbook.sol";

contract LogbookTest is Test {
    Logbook private logbook;

    address constant DEPLOYER = address(176);
    address constant TRAVELOGGERS_OWNER = address(177);
    address constant PUBLIC_SALE_MINTER = address(178);
    address constant ATTACKER = address(179);
    address constant APPROVED = address(180);
    address constant FRONTEND_OPERATOR = address(181);

    uint256 constant _ROYALTY_BPS_LOGBOOK_OWNER = 8000;
    uint256 private constant _ROYALTY_BPS_COMMISSION_MAX = 10000 - _ROYALTY_BPS_LOGBOOK_OWNER;
    uint256 constant _PUBLIC_SALE_ON = 1;
    uint256 constant _PUBLIC_SALE_OFF = 2;

    uint256 constant CLAIM_TOKEN_START_ID = 1;
    uint256 constant CLAIM_TOKEN_END_ID = 1500;

    event SetTitle(uint256 indexed tokenId, string title);

    event SetDescription(uint256 indexed tokenId, string description);

    event SetForkPrice(uint256 indexed tokenId, uint256 amount);

    event Content(address indexed author, bytes32 indexed contentHash, string content);

    event Publish(uint256 indexed tokenId, bytes32 indexed contentHash);

    event Fork(uint256 indexed tokenId, uint256 indexed newTokenId, address indexed owner, uint32 end, uint256 amount);

    event Donate(uint256 indexed tokenId, address indexed donor, uint256 amount);

    enum RoyaltyPurpose {
        Fork,
        Donate
    }
    event Pay(
        uint256 indexed tokenId,
        address indexed sender,
        address indexed recipient,
        RoyaltyPurpose purpose,
        uint256 amount
    );

    event Withdraw(address indexed account, uint256 amount);

    function setUp() public {
        // Deploy contract with DEPLOYER
        vm.prank(DEPLOYER);
        logbook = new Logbook("Logbook", "LOGRS");

        // label addresses
        vm.label(DEPLOYER, "DEPLOYER");
        vm.label(TRAVELOGGERS_OWNER, "TRAVELOGGERS_OWNER");
        vm.label(PUBLIC_SALE_MINTER, "PUBLIC_SALE_MINTER");
        vm.label(ATTACKER, "ATTACKER");
        vm.label(APPROVED, "APPROVED");
        vm.label(FRONTEND_OPERATOR, "FRONTEND_OPERATOR");
    }

    /**
     * Claim
     */
    function _claimToTraveloggersOwner() private {
        uint160 blockTime = 1647335928;
        vm.prank(DEPLOYER);
        vm.warp(blockTime);
        logbook.claim(TRAVELOGGERS_OWNER, CLAIM_TOKEN_START_ID);
        assertEq(logbook.ownerOf(CLAIM_TOKEN_START_ID), TRAVELOGGERS_OWNER);
        assertEq(logbook.balanceOf(TRAVELOGGERS_OWNER), 1);

        ILogbook.Book memory book = logbook.getLogbook(CLAIM_TOKEN_START_ID);
        assertEq(uint160(block.timestamp), blockTime);
        assertEq(block.timestamp, book.createdAt);
    }

    function testClaim() public {
        // only owner
        vm.prank(PUBLIC_SALE_MINTER);
        vm.expectRevert("Ownable: caller is not the owner");
        logbook.claim(TRAVELOGGERS_OWNER, CLAIM_TOKEN_END_ID);

        // token has not been claimed yet
        vm.expectRevert("ERC721: owner query for nonexistent token");
        logbook.ownerOf(CLAIM_TOKEN_START_ID);

        assertEq(logbook.balanceOf(TRAVELOGGERS_OWNER), 0);

        // claim
        _claimToTraveloggersOwner();

        // token can't be claimed twice
        vm.prank(DEPLOYER);
        vm.expectRevert("ERC721: token already minted");
        logbook.claim(TRAVELOGGERS_OWNER, CLAIM_TOKEN_START_ID);

        // invalid token id
        vm.prank(DEPLOYER);
        vm.expectRevert(abi.encodeWithSignature("InvalidTokenId(uint256,uint256)", 1, 1500));
        logbook.claim(TRAVELOGGERS_OWNER, CLAIM_TOKEN_START_ID - 1);

        vm.prank(DEPLOYER);
        vm.expectRevert(abi.encodeWithSignature("InvalidTokenId(uint256,uint256)", 1, 1500));
        logbook.claim(TRAVELOGGERS_OWNER, CLAIM_TOKEN_END_ID + 1);
    }

    /**
     * Public Sale
     */
    function testPublicSale() public {
        uint256 price = 1 ether;

        // not started
        vm.expectRevert(abi.encodePacked(bytes4(keccak256("PublicSaleNotStarted()"))));
        logbook.publicSaleMint();

        // turn on
        vm.prank(DEPLOYER);
        logbook.turnOnPublicSale();
        vm.prank(DEPLOYER);
        logbook.setPublicSalePrice(price);
        assertEq(logbook.publicSalePrice(), price);

        // mint
        uint256 deployerWalletBalance = DEPLOYER.balance;
        vm.deal(PUBLIC_SALE_MINTER, price + 1 ether);
        vm.prank(PUBLIC_SALE_MINTER);
        uint256 tokenId = logbook.publicSaleMint{value: price}();
        assertEq(tokenId, CLAIM_TOKEN_END_ID + 1);
        assertEq(logbook.ownerOf(tokenId), PUBLIC_SALE_MINTER);

        // deployer receives ether
        assertEq(DEPLOYER.balance, deployerWalletBalance + price);

        // not engough ether to mint
        vm.expectRevert(abi.encodeWithSignature("InsufficientAmount(uint256,uint256)", price - 0.01 ether, price));
        vm.deal(PUBLIC_SALE_MINTER, price + 1 ether);
        vm.prank(PUBLIC_SALE_MINTER);
        logbook.publicSaleMint{value: price - 0.01 ether}();

        // free to mint
        vm.prank(DEPLOYER);
        logbook.setPublicSalePrice(0);
        assertEq(logbook.publicSalePrice(), 0);
        vm.prank(PUBLIC_SALE_MINTER);
        uint256 freeTokenId = logbook.publicSaleMint{value: 0}();
        assertEq(freeTokenId, CLAIM_TOKEN_END_ID + 2);
        assertEq(logbook.ownerOf(freeTokenId), PUBLIC_SALE_MINTER);
    }

    /**
     * Title, Description, Fork Price, Publish...
     */
    function _setForkPrice(uint256 forkPrice) private {
        vm.expectEmit(true, true, false, false);
        emit SetForkPrice(CLAIM_TOKEN_START_ID, forkPrice);

        vm.prank(TRAVELOGGERS_OWNER);
        logbook.setForkPrice(CLAIM_TOKEN_START_ID, forkPrice);

        ILogbook.Book memory book = logbook.getLogbook(CLAIM_TOKEN_START_ID);
        assertEq(book.forkPrice, forkPrice);
    }

    function _publish(string memory content, bool emitContent) private returns (bytes32 contentHash) {
        contentHash = keccak256(abi.encodePacked(content));

        // emit Content
        if (emitContent) {
            vm.expectEmit(true, true, true, false);
            emit Content(TRAVELOGGERS_OWNER, contentHash, content);
        }

        // emit Publish
        vm.expectEmit(true, true, false, false);
        emit Publish(CLAIM_TOKEN_START_ID, contentHash);

        vm.prank(TRAVELOGGERS_OWNER);
        logbook.publish(CLAIM_TOKEN_START_ID, content);
    }

    function testSetTitle() public {
        _claimToTraveloggersOwner();
        string memory title = "Sit deserunt nulla aliqua ex nisi";

        // set title
        vm.prank(TRAVELOGGERS_OWNER);
        vm.expectEmit(true, true, false, false);
        emit SetTitle(CLAIM_TOKEN_START_ID, title);
        logbook.setTitle(CLAIM_TOKEN_START_ID, title);

        // only logbook owner
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodePacked(bytes4(keccak256("Unauthorized()"))));
        logbook.setTitle(CLAIM_TOKEN_START_ID, title);

        // approve other address
        vm.startPrank(TRAVELOGGERS_OWNER);
        logbook.approve(APPROVED, CLAIM_TOKEN_START_ID);
        logbook.getApproved(CLAIM_TOKEN_START_ID);
        vm.stopPrank();

        vm.prank(APPROVED);
        logbook.setTitle(CLAIM_TOKEN_START_ID, title);
    }

    function testSetDescription() public {
        _claimToTraveloggersOwner();
        string
            memory description = "Quis commodo sunt ea est aliquip enim aliquip ullamco eu. Excepteur aliquip enim irure dolore deserunt fugiat consectetur esse in deserunt commodo in eiusmod esse. Cillum cupidatat dolor voluptate in id consequat nulla aliquip. Deserunt sunt aute eu aliqua consequat nulla aliquip excepteur exercitation. Lorem ex magna deserunt duis dolor dolore mollit.";

        // set description
        vm.prank(TRAVELOGGERS_OWNER);
        vm.expectEmit(true, true, false, false);
        emit SetDescription(CLAIM_TOKEN_START_ID, description);
        logbook.setDescription(CLAIM_TOKEN_START_ID, description);

        // only logbook owner
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodePacked(bytes4(keccak256("Unauthorized()"))));
        logbook.setTitle(CLAIM_TOKEN_START_ID, description);
    }

    function testSetForkPrice() public {
        _claimToTraveloggersOwner();

        // set fork price
        uint256 forkPrice = 0.1 ether;
        _setForkPrice(forkPrice);

        // only logbook owner
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodePacked(bytes4(keccak256("Unauthorized()"))));
        logbook.setForkPrice(CLAIM_TOKEN_START_ID, forkPrice);
    }

    function testPublish(string calldata content) public {
        _claimToTraveloggersOwner();
        bytes32 contentHash = keccak256(abi.encodePacked(content));

        // publish
        bytes32 returnContentHash = _publish(content, true);
        assertEq(contentHash, returnContentHash);
        ILogbook.Book memory book = logbook.getLogbook(CLAIM_TOKEN_START_ID);
        assertEq(book.logCount, 1);

        // publish same content
        bytes32 return2ContentHash = _publish(content, false);
        assertEq(contentHash, return2ContentHash);
        ILogbook.Book memory book2 = logbook.getLogbook(CLAIM_TOKEN_START_ID);
        assertEq(book2.logCount, 2);

        // only logbook owner
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodePacked(bytes4(keccak256("Unauthorized()"))));
        logbook.publish(CLAIM_TOKEN_START_ID, content);
    }

    function testPublishZh20() public {
        _claimToTraveloggersOwner();
        string memory content = unicode"愛倫坡驚悚小說全集，坎坷的奇才，大家好。";
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        bytes32 returnContentHash = _publish(content, true);
        assertEq(contentHash, returnContentHash);
    }

    function testPublishZh50() public {
        _claimToTraveloggersOwner();
        string
            memory content = unicode"愛倫坡驚悚小說全集，坎坷的奇才，大家好，我係今集已讀不回主持人Serrini。熱辣辣嘅暑假最適合咩？";
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        bytes32 returnContentHash = _publish(content, true);
        assertEq(contentHash, returnContentHash);
    }

    function testPublishZh100() public {
        _claimToTraveloggersOwner();
        string
            memory content = unicode"愛倫坡驚悚小說全集，坎坷的奇才，大家好，我係今集已讀不回主持人Serrini。熱辣辣嘅暑假最適合咩？愛倫坡驚悚小說全集，坎坷的奇才，大家好，我係今集已讀不回主持人Serrini。熱辣辣嘅暑假最適合咩？";
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        bytes32 returnContentHash = _publish(content, true);
        assertEq(contentHash, returnContentHash);
    }

    function testPublishZh200() public {
        _claimToTraveloggersOwner();
        string
            memory content = unicode"愛倫坡驚悚小說全集，坎坷的奇才，大家好，我係今集已讀不回主持人Serrini。熱辣辣嘅暑假最適合咩？愛倫坡驚悚小說全集，坎坷的奇才，大家好，我係今集已讀不回主持人Serrini。熱辣辣嘅暑假最適合咩？愛倫坡驚悚小說全集，坎坷的奇才，大家好，我係今集已讀不回主持人Serrini。熱辣辣嘅暑假最適合咩？愛倫坡驚悚小說全集，坎坷的奇才，大家好，我係今集已讀不回主持人Serrini。熱辣辣嘅暑假最適合咩？";
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        bytes32 returnContentHash = _publish(content, true);
        assertEq(contentHash, returnContentHash);
    }

    function testPublishZh500() public {
        _claimToTraveloggersOwner();
        string
            memory content = unicode"我覺得大家會好喜歡今天介紹嘅書。\n學者James Cooper Lawrence係1917年有篇有趣嘅文章 “A Theory of the Short Story” 「短篇小說的理論」就提到愛倫坡話過自己比較prefer短篇，就係因為短篇嘅小說可以最可以做到簡潔、完整。情況就好似讀者可以將故事世界置於掌心、唔洗時刻記住20個角色同埋接受大量情境setting資料就可以走入故事。可能坡哥對人嘅耐心無咩信心，佢覺得比讀者控制到個故事篇幅先可以令人全程投入。佢創作短篇小說嘅重點就在於傳達一個single effect，唔係就變就你地d 分手千字文架啦。\n愛倫坡係短篇小說、詩歌、評論文章都set到個bar好高，堪稱冠絕同代美國作家。以下我地講下愛倫坡嘅小說寫作風格，等大家可以調整一下期望。愛倫坡嘅作品比較容易比讀者get到嘅風格就係一種揉合帶有古典味、歌德色嘅浪漫主義嘅「坡體」（個term只存在這個book channel）。他寫作風格靠近浪漫主義，因為其文字偏重騰飛嘅思想同自言自語講情感，有拜倫、雪萊之風，簡單地說就係「腦海想旅行」、唔係幾現實，甚至係避世，都同上面提到「為藝術而藝術」幾配合。";
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        bytes32 returnContentHash = _publish(content, true);
        assertEq(contentHash, returnContentHash);
    }

    function testPublishZh2000() public {
        _claimToTraveloggersOwner();
        string
            memory content = unicode"常言道，食餐好可以令心情好，心情唔好更加要食餐好，飲食係美好生活的重要一環，而香港都算係國際美食之都，好多香港人都算係為食架。但係食得太多太好又會影響健康，會有三高糖尿病等富貴病，或者肥左少少都會令心情緊張，所以做一個為食的人，都係充滿掙扎的一件事。今次想同大家介紹的書是一本飲食文化史，《饞——貪吃的歷史》，從文化角度了解下我地為食一族的各種面貌和歷史意義。\n我本人是否為食呢？在這裡跟大家分享一個小故事。話說我中學時得過一個徵文比賽的獎項，個頒獎禮有幾十人得獎，豬肉味有啲濃。個幾十人的茶會有個重點環節，就係大作家，金庸會來跟我們合照，合照完之後還可以請金庸簽名。金庸人人仰幕，大家當然帶好書。合照完左，茶會開始，但所有人都去排隊請金庸先生簽名，我眼前是，一邊係幾十人排隊等待的金庸，一邊係無人問津的茶點（水平普通），而我，當時選擇了——茶點。全場只得我一個中學生，先去食茶點，等條隊無乜人排時，才施施然去請金庸簽名。這個選擇背後的勇氣來自什麼，我都好難講清楚，是反叛還是什麼，我在今日這個場合承認，是因為，單純的為食。究竟為食呢樣嘢，係令你生活更加美好還是阻止你生活變得更加美好呢？不妨來讀這本書思考一下。\n《饞——貪吃的歷史》的作者弗羅杭．柯立葉是一位專門研究飲食的歷史學家及作家，本書是得過書獎的。書中由宗教典籍、嚴肅文學、民間文學、藝術繪畫、報章漫畫、民俗資料，展示了「饞」這個概念及相關概念，展示了它的各種形態與流變，是一本飽覽貪吃眾生相的飲食文化史。在書中可以看到許多藝術繪畫，又可以順便認識好多文學作品，可謂營養豐富，賞心悅目，秀色可餐。\n在早期，「饞」是一件大事，大家都知，聖經的七宗罪裡就有一條「饕餮」，即是極度為食，這個中文翻譯亦都很雅，饕餮本來是古代中國神話中的怪物，《史記》裡面有佢個名，青銅器上會有佢個樣，《山海經》有佢比較詳細的形象。簡單來講，饕餮很貪吃，會食人，所以代表了貪婪的罪惡。傳統上中國也將貪吃的人稱為老饕。我猜你平時見到饕餮兩個字都不識讀的了，學多兩個字是否很開心？這樣談飲食是否更有文化？這本書一\n開始就有一章是梳理書名「饞」gourmandise有關的詞，好有文化，我硬食了幾十個法文西班牙文意大利文拉丁文生詞……原來「饞」gourmandise的詞義在歷史上一直變化，簡單來講有三個面向：glouton（暴食，即是饕餮）， gourmet（講究美食）， gourmand（貪嘴），我今日的法文課可否到此為止……所以饞的意思可指帶罪惡意味的暴食、講究美食（比較有知識和文化味）、及比較日常的貪嘴為食，而這三個解釋大致符合歷史的流向，以及本書的結構。\n在中世紀的教會眼中，貪饞為食與教會苦修節制的美德相反，雖然貪饞只是輕罪，但也列入七大宗罪，因為貪饞會引起其它的罪惡。大家不要忘了，人類之所以會從失樂園墮落，都係因為夏娃同亞當吃了蘋果，中世紀很多神學家都認為人類的原罪包括貪饞。貪饞容易引起口舌之禍，飲飽食醉之後會做滑稽放蕩的行為，會亂講話，傻笑之類，又容易驕傲、嫉妒等其它罪惡。而進食用口部，口部是語言和食物交會的十字路口，教會眼中是很容易受到撒旦侵襲的。所以修道院規定進食時必須保持沉默，並以大聲朗誦聖經篇章代替席間交談，其實是想提醒食客靈魂的糧食比身體糧食更重要，而聽覺比味覺更高尚。落到胃部就更麻煩了，因為腹部和腹部以下的性器相連，「飲食男女，人之大欲存焉」，「食色性也」，飲食和性欲被認為是非常接近的東西，又好容易曳曳了。所謂「飽暖思淫慾」，原來古代的中西方都是這樣想。甚至，在法文中，有些話女性貪食的字眼，其實也意近她性方面不檢點。噢，原來話女人「大食」作為性意味的侮辱，廣東人和法國人竟然在這方面相通，利害利害。\n教會一度大力鞭撻暴飲暴食之罪，在聖經手抄本、壁畫、教堂雕飾、版畫等地方大肆醜化暴食者，將之畫成狼、豬、癩蛤蟆等等，也將暴飲暴食描述為有財有勢者的專屬犯罪。不過也造成了貪饞在藝術史上的源遠流長，file幾呎厚。另一方面大力提倡齋戒、節制等美德，又一度主張禁食，但問題來了，植物、動物、美食，其實都是上帝的造物，如果一味禁食、厭惡美食，那麼如何欣賞上帝的創造呢？這豈非和上帝距離愈來愈遠嗎？而且，饑餓感、食慾都是上帝創造的嘛，不用覺得它們是邪惡的，所以有些神學家都主張大家平常心一點去看待，不必讉責吃喝的慾望，也不用鞭撻飲食享樂，只是要追求適度、節制、平衡，也要有禮儀以滿足社交要求，同時滿足個人生理需要和賓客的精神需要。大概由十三世紀，適度飲食的理想已代替了禁食的理想。\n教會很努力向世俗世界傳遞節制的美德，但事實上，由十三世紀左右開始，民間有一些相反的體裁重新興起，就是關於極樂世界的故事、詩歌、鬧劇、圖畫、版畫、漫畫地圖等。這種極樂世界不是宗教裡的天堂，而是民間的想像，它們都經常描述一個食物供應源源不絕、種類超級豐富的人間仙境間仙境。";
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        bytes32 returnContentHash = _publish(content, true);
        assertEq(contentHash, returnContentHash);
    }

    function testPublishZh5000() public {
        _claimToTraveloggersOwner();
        string
            memory content = unicode"《饞——貪吃的歷史》\n常言道，食餐好可以令心情好，心情唔好更加要食餐好，飲食係美好生活的重要一環，而香港都算係國際美食之都，好多香港人都算係為食架。但係食得太多太好又會影響健康，會有三高糖尿病等富貴病，或者肥左少少都會令心情緊張，所以做一個為食的人，都係充滿掙扎的一件事。今次想同大家介紹的書是一本飲食文化史，《饞——貪吃的歷史》，從文化角度了解下我地為食一族的各種面貌和歷史意義。\n我本人是否為食呢？在這裡跟大家分享一個小故事。話說我中學時得過一個徵文比賽的獎項，個頒獎禮有幾十人得獎，豬肉味有啲濃。個幾十人的茶會有個重點環節，就係大作家，金庸會來跟我們合照，合照完之後還可以請金庸簽名。金庸人人仰幕，大家當然帶好書。合照完左，茶會開始，但所有人都去排隊請金庸先生簽名，我眼前是，一邊係幾十人排隊等待的金庸，一邊係無人問津的茶點（水平普通），而我，當時選擇了——茶點。全場只得我一個中學生，先去食茶點，等條隊無乜人排時，才施施然去請金庸簽名。這個選擇背後的勇氣來自什麼，我都好難講清楚，是反叛還是什麼，我在今日這個場合承認，是因為，單純的為食。究竟為食呢樣嘢，係令你生活更加美好還是阻止你生活變得更加美好呢？不妨來讀這本書思考一下。\n《饞——貪吃的歷史》的作者弗羅杭．柯立葉是一位專門研究飲食的歷史學家及作家，本書是得過書獎的。書中由宗教典籍、嚴肅文學、民間文學、藝術繪畫、報章漫畫、民俗資料，展示了「饞」這個概念及相關概念，展示了它的各種形態與流變，是一本飽覽貪吃眾生相的飲食文化史。在書中可以看到許多藝術繪畫，又可以順便認識好多文學作品，可謂營養豐富，賞心悅目，秀色可餐。\n一、為食好大罪\n在早期，「饞」是一件大事，大家都知，聖經的七宗罪裡就有一條「饕餮」，即是極度為食，這個中文翻譯亦都很雅，饕餮本來是古代中國神話中的怪物，《史記》裡面有佢個名，青銅器上會有佢個樣，《山海經》有佢比較詳細的形象。簡單來講，饕餮很貪吃，會食人，所以代表了貪婪的罪惡。傳統上中國也將貪吃的人稱為老饕。我猜你平時見到饕餮兩個字都不識讀的了，學多兩個字是否很開心？這樣談飲食是否更有文化？這本書一開始就有一章是梳理書名「饞」gourmandise有關的詞，好有文化，我硬食了幾十個法文西班牙文意大利文拉丁文生詞……原來「饞」gourmandise的詞義在歷史上一直變化，簡單來講有三個面向：glouton（暴食，即是饕餮）， gourmet（講究美食）， gourmand（貪嘴），我今日的法文課可否到此為止……所以饞的意思可指帶罪惡意味的暴食、講究美食（比較有知識和文化味）、及比較日常的貪嘴為食，而這三個解釋大致符合歷史的流向，以及本書的結構。\n在中世紀的教會眼中，貪饞為食與教會苦修節制的美德相反，雖然貪饞只是輕罪，但也列入七大宗罪，因為貪饞會引起其它的罪惡。大家不要忘了，人類之所以會從失樂園墮落，都係因為夏娃同亞當吃了蘋果，中世紀很多神學家都認為人類的原罪包括貪饞。貪饞容易引起口舌之禍，飲飽食醉之後會做滑稽放蕩的行為，會亂講話，傻笑之類，又容易驕傲、嫉妒等其它罪惡。而進食用口部，口部是語言和食物交會的十字路口，教會眼中是很容易受到撒旦侵襲的。所以修道院規定進食時必須保持沉默，並以大聲朗誦聖經篇章代替席間交談，其實是想提醒食客靈魂的糧食比身體糧食更重要，而聽覺比味覺更高尚。落到胃部就更麻煩了，因為腹部和腹部以下的性器相連，「飲食男女，人之大欲存焉」，「食色性也」，飲食和性欲被認為是非常接近的東西，又好容易曳曳了。所謂「飽暖思淫慾」，原來古代的中西方都是這樣想。甚至，在法文中，有些話女性貪食的字眼，其實也意近她性方面不檢點。噢，原來話女人「大食」作為性意味的侮辱，廣東人和法國人竟然在這方面相通，利害利害。\n教會一度大力鞭撻暴飲暴食之罪，在聖經手抄本、壁畫、教堂雕飾、版畫等地方大肆醜化暴食者，將之畫成狼、豬、癩蛤蟆等等，也將暴飲暴食描述為有財有勢者的專屬犯罪。不過也造成了貪饞在藝術史上的源遠流長，file幾呎厚。另一方面大力提倡齋戒、節制等美德，又一度主張禁食，但問題來了，植物、動物、美食，其實都是上帝的造物，如果一味禁食、厭惡美食，那麼如何欣賞上帝的創造呢？這豈非和上帝距離愈來愈遠嗎？而且，饑餓感、食慾都是上帝創造的嘛，不用覺得它們是邪惡的，所以有些神學家都主張大家平常心一點去看待，不必讉責吃喝的慾望，也不用鞭撻飲食享樂，只是要追求適度、節制、平衡，也要有禮儀以滿足社交要求，同時滿足個人生理需要和賓客的精神需要。大概由十三世紀，適度飲食的理想已代替了禁食的理想。\n二、放縱與節制\n教會很努力向世俗世界傳遞節制的美德，但事實上，由十三世紀左右開始，民間有一些相反的體裁重新興起，就是關於極樂世界的故事、詩歌、鬧劇、圖畫、版畫、漫畫地圖等。這種極樂世界不是宗教裡的天堂，而是民間的想像，它們都經常描述一個食物供應源源不絕、種類超級豐富的人間仙境，人在其中不用工作，就是隨時隨意地大吃大喝，歌舞作樂，根本不知饑餓感為何物。更早期公元前五世紀的古希臘喜劇也類似，烤雲雀會直接由天上掉入人的口中，河流是浮著肉的濃湯，魚群自動送上門，自行油炸送入食客口中，樹上直接掉下杏仁饀餅和烤羊腸。中世紀的烏托邦裡永遠是春天和夏天，人類完全沉浸在感官享樂的世俗幸福中，無限放題，又唔駛做，又唔會老。\n（讀P.48極樂世界）\n各個不同國家的極樂世界飲食詩結構大致一樣，但會出現不同地區的獨特美食。例如法國的極樂世界，河川是紅酒和白酒（都是名貴產地），荷蘭版本就多了一條啤酒河；意大利的極樂世界牆紙是圓型的沙樂美腸，又會有一座由乳酪絲組成的高山，會噴出通心粉，接著跌入醬汁河裡。而在這個世界裡「肥」是一個正面的詞語，代表了豐饒富足、無憂無慮。極樂世界完全係民間世俗的想像，後來逐漸又演變成邊緣人物流放的桃花源，好似愈講愈正咁。\n值得注意的是，這種狂歡節般的想像，其實是因為現實中連年的大饑荒，民間食品供應極度不足又面對嚴厲的宗教規管，所以才在想像的世界中尋求慰藉，也是緬懷逝去的昔日。這是一種民間自行尋找安定人心的方式，是一種宣洩的管道、短暫的補償。其實在聖經中，都是在大洪水之後，神才開始允許挪亞及其後代吃肉和喝酒，見到人類生活每況愈下神都會讓步。如果在很困難的時候還不讓人發洩和想像，真是太殘忍了。\n極樂世界烏托邦想像早期曾有反抗天主教教條的意味，但真正擊敗天主教教條的不是極樂世界，而是天主教本身的腐敗。十三世紀以降天主教對美食的規訓放鬆，教廷又有錢，結果就出現了「美食齋戒」這樣荒謬的觀念，於是就出現許多描述宗教人員和修道院放奢華飲食、酒池肉林的諷刺文學，例如說他們是「大腹神學家」，將之前在宗教繪畫裡貪食者的形象用來描繪貪食修士等等。這一點甚至是十六世紀宗教改革時，基督新教對羅馬天主教的主要抨擊目標之一。基督教對於美食的態度可用英國飲食文化來代表：英國只是考慮食材和食物的養份、維他命及機能。而天主教則已經累積了許多種植、飲食的技藝和知識，已比較似法國人和意大利人那樣考慮烹飪藝術的觀點。天主教面對指責，進行了對美食的除罪化，也同時提倡適度而不豪奢的飲食，這有助催生一種為食的美學：只要能遵守規範，食好嘢的樂趣就可以被肯定，而所有規範中最重要的就是餐桌禮儀和分享之樂。\n三、美食的知識和教養\n由十六、十七世紀左右，由天主教和西方社會推動的「美食文化菁英化」運動，首先就是唾棄貪食者、暴食者，但推崇端正得體，知識豐富的「饕客」和美食家。到十八世紀，法國上流菁英已經視享樂為飲食的目的，而「貪饞」gourmandise這個詞也開始被收入百科全書，意即「對美食細膩而無節制的喜好」，雖然褒貶參半，但「細緻的喜好」已經出現了，不再只是「不知節制」。\n端正得體的饕客著重餐桌禮儀，重要參考物就是人稱「人文主義王子」伊拉斯謨的《兒童禮儀》，這本書是參考古典文學（如亞里士多德、西塞羅）、中世紀的教育論著、諺語、寓言故事，制定一套社會接納的行為準則。如何盛菜、切菜、放入口、咀嚼，都有規定。這套優雅的準則被沿用了五世紀之久，可說是演化緩慢。而餐桌禮儀的敵人當然就是粗魯的「饕餮之徒」啦，由文藝復興到啟蒙運動期間，都有好多文學作品描述他們的醜態。\n//可讀p.111//\n儀態之後就是品味，1803年美食享樂主義者格里蒙．德．拉雷涅《饕客年鑑》，應該算係米芝蓮前身，就是飲食品味的重要指標。而飲食的高雅品味離不開高級的語言能力，一個美食家需要用優美的語言去形容食物，並指出它的來源地和烹飪方法。食物本身也開始象徵身份地位，例如鷹嘴豆、蘿蔔、扁豆、黑血腸就是窮人的食物，時鮮的蘆荀、朝鮮薊、甜瓜、無花果及西洋梨就是上流社會的喜好，果醬、蜜餞、杏仁小餅之類的甜食都是高貴嘢。上流的饕客端正得體，儀容整潔、容光煥發，而下等的饕餮之後就猥瑣、貪婪、肥而走樣，因為必須能掌控自己的身體，才是上流人。\n飲食有知識，有教養，有節制，有合理的熱情，現在我愈講愈健康，愈完美了，但作者一邊梳理飲食文化如何成為法國文化最有代表性的一環，也有指出所謂上流、規範的虛榮、浮華與自相矛盾。他也沒有忽略到，在這些看來普世而體面的規範當中，有一些東西是被邊緣化的，例如，女性。女性經常被認為只愛吃甜食，這是一種像小孩子般幼稚的表現，所以女性不會懂得真正欣賞美食，真正要去品嚐美食就不要帶女性了，只會令你分心。而許多關於女性與食物的刻板想法也是荒謬可笑的，例如覺得女人的胃口與性欲是呈正比的，戀愛中的女人就應該食欲好好，所以如果你和女人吃飯她沒有胃口，你就不用想下一步了——這真是毫無道理，完全錯晒。同時，女性又常被食物隱喻來寫，所謂「秀色可餐」。\n//p180-182//\n不過這本書並沒有跌入超級政治正確的問題，沒有太過讉責這些有性別意味的措辭，他摘錄了大量資料，只偶然地幽默調侃一下，其餘就讓讀者自己判斷，這種應該是一個歷史學家的眼光，保留著歷史的多元性，並讓歷史來回應當下。至於到底「饞」gourmandise有多正面多負面，我們對飲食的欲望應該節制到什麼程度、放縱到什麼程度，作者本身的態度是怎樣呢？我隱隱覺得他是稍稍傾向放縱那一邊的，因為他應該比較反對節制，他欣賞的是比「適度」多一點點。但客觀來看，作者所呈現的貪饞文化史，總是在兩種張力之間游走的，因為正如巴塔耶說，哪裡有禁忌，哪裡有踰越，為食都是在放縱中充滿掙扎的生存狀態，因為在控制的邊界反而可以看到更多元的存在。究竟為食呢樣嘢，係令你生活更加美好還是阻止你生活變得更加美好呢？看完本書後，至少可以說，為食有令人類文化史更加豐富美好。\n儀態之後就是品味，1803年美食享樂主義者格里蒙．德．拉雷涅《饕客年鑑》，應該算係米芝蓮前身，就是飲食品味的重要指標。而飲食的高雅品味離不開高級的語言能力，一個美食家需要用優美的語言去形容食物，並指出它的來源地和烹飪方法。食物本身也開始象徵身份地位，例如鷹嘴豆、蘿蔔、扁豆、黑血腸就是窮人的食物，時鮮的蘆荀、朝鮮薊、甜瓜、無花果及西洋梨就是上流社會的喜好，果醬、蜜餞、杏仁小餅之類的甜食都是高貴嘢。上流的饕客端正得體，儀容整潔、容光煥發，而下等的饕餮之後就猥瑣、貪婪、肥而走樣，因為必須能掌控自己的身體，才是上流人。\n飲食有知識，有教養，有節制，有合理的熱情，現在我愈講愈健康，愈完美了，但作者一邊梳理飲食文化如何成為法國文化最有代表性的一環，也有指出所謂上流、規範的虛榮、浮華與自相矛盾。他也沒有忽略到，在這些看來普世而體面的規範當中，有一些東西是被邊緣化的，例如，女性。女性經常被認為只愛吃甜食，這是一種像小孩子般幼稚的表現，所以女性不會懂得真正欣賞美食，真正要去品嚐美食就不要帶女性了，只會令你分心。而許多關於女性與食物的刻板想法也是荒謬可笑的，例如覺得女人的胃口與性欲是呈正比的，戀愛中的女人就應該食欲好好，所以如果你和女人吃飯她沒有胃口，你就不用想下一步了——這真是毫無道理，完全錯晒。同時，女性又常被食物隱喻來寫，所謂「秀色可餐」。\n由十六、十七世紀左右，由天主教和西方社會推動的「美食文化菁英化」運動，首先就是唾棄貪食者、暴食者，但推崇端正得體，知識豐富的「饕客」和美食家。到十八世紀，法國上流菁英已經視享樂為飲食的目的，而「貪饞」gourmandise這個詞也開始被收入百科全書。";
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        bytes32 returnContentHash = _publish(content, true);
        assertEq(contentHash, returnContentHash);
    }

    function testPublishEn50() public {
        _claimToTraveloggersOwner();
        string memory content = "iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii";
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        bytes32 returnContentHash = _publish(content, true);
        assertEq(contentHash, returnContentHash);
    }

    function testPublishEn140() public {
        _claimToTraveloggersOwner();
        string
            memory content = "iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii";
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        bytes32 returnContentHash = _publish(content, true);
        assertEq(contentHash, returnContentHash);
    }

    function testPublishEn200() public {
        _claimToTraveloggersOwner();
        string
            memory content = "Even if they fail to deter him, they are still valuable to isolate Russia from the world and as a punishment, according to Steven Pifer, a former US ambassador to Ukraine, appearing Thursday on CNNNN.";
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        bytes32 returnContentHash = _publish(content, true);
        assertEq(contentHash, returnContentHash);
    }

    function testPublishEn300() public {
        _claimToTraveloggersOwner();
        string
            memory content = "iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii";
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        bytes32 returnContentHash = _publish(content, true);
        assertEq(contentHash, returnContentHash);
    }

    function testPublishEn500() public {
        _claimToTraveloggersOwner();
        string
            memory content = "iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii";
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        bytes32 returnContentHash = _publish(content, true);
        assertEq(contentHash, returnContentHash);
    }

    function testPublishEn1000() public {
        _claimToTraveloggersOwner();
        string
            memory content = "iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii";
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        bytes32 returnContentHash = _publish(content, true);
        assertEq(contentHash, returnContentHash);
    }

    function testPublishEn2000() public {
        _claimToTraveloggersOwner();
        string
            memory content = "US markets rebounded, while Russia's haven't yet. Egan noted that the stock market dropped in the morning after news of the attacks on Ukraine, but then rebounded after Biden announced sanctions.\nRussia's stock market, on the other hand, lost a third of its value. The value of the ruble also tumbled.\n\"There are some real concerns from investors about Russia becoming a pariah state at this point,\" he said.\nConsider the unlikely nightmare scenario. I talked to Tom Collina, policy director at the Ploughshares Fund -- which pushes to eliminate the dangers posed by nuclear weapons -- about what it means for the US and Russia, the world's two top nuclear countries, to be in a standoff.\nHe said Putin's new demeanor means the world needs to view him differently. The worst possible scenario, which is very unlikely, is the US and Russia in an armed conflict and a miscalculation triggering nuclear war.\n\"I think all bets are off as to knowing what he's going to do next,\" Collina said.\nNobody wants to trigger such a scenario, but with nuclear powers in conflict, there is major concern.\n\"Even if they don't want to get into a nuclear conflict, they could by accident or miscalculation,\" Collina said. \"In the fog of war, things can happen that no one ever wanted to happen.\"\nThere is already nuclear talk. Ukraine used to house many of the Soviet Union's nuclear weapons but gave them up in 1994 in exchange for a security guarantee, known as the Budapest Memorandum, from the US, the United Kingdom and Russia. That promise was clearly violated this week.\nPutin made up a conspiracy theory that the US and Ukraine were plotting to place nuclear weapons back in Ukraine as a pretext for his invasion.\nFrench Foreign Minister Jean-Yves Le Drian said Thursday on French television, according to Reuters, that his country viewed some of Putin's recent comments as a threat to use nuclear weapons in the Ukraine conflict.\n\"Yes, I think that Vladimir Putin must also understand that the Atlantic alliance is a nuclear alliance.\n";
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        bytes32 returnContentHash = _publish(content, true);
        assertEq(contentHash, returnContentHash);
    }

    function testPublishEn5000() public {
        _claimToTraveloggersOwner();
        string
            memory content = "US markets rebounded, while Russia's haven't yet. Egan noted that the stock market dropped in the morning after news of the attacks on Ukraine, but then rebounded after Biden announced sanctions.\nRussia's stock market, on the other hand, lost a third of its value. The value of the ruble also tumbled.\"There are some real concerns from investors about Russia becoming a pariah state at this point,\" he said.Consider the unlikely nightmare scenario. I talked to Tom Collina, policy director at the Ploughshares Fund -- which pushes to eliminate the dangers posed by nuclear weapons -- about what it means for the US and Russia, the world's two top nuclear countries, to be in a standoff.\nHe said Putin's new demeanor means the world needs to view him differently. The worst possible scenario, which is very unlikely, is the US and Russia in an armed conflict and a miscalculation triggering nuclear war.\"I think all bets are off as to knowing what he's going to do next,\" Collina said.\nNobody wants to trigger such a scenario, but with nuclear powers in conflict, there is major concern.\"Even if they don't want to get into a nuclear conflict, they could by accident or miscalculation,\" Collina said. \"In the fog of war, things can happen that no one ever wanted to happen.\"\nThere is already nuclear talk. Ukraine used to house many of the Soviet Union's nuclear weapons but gave them up in 1994 in exchange for a security guarantee, known as the Budapest Memorandum, from the US, the United Kingdom and Russia. That promise was clearly violated this week.\nPutin made up a conspiracy theory that the US and Ukraine were plotting to place nuclear weapons back in Ukraine as a pretext for his invasion.\nFrench Foreign Minister Jean-Yves Le Drian said Thursday on French television, according to Reuters, that his country viewed some of Putin's recent comments as a threat to use nuclear weapons in the Ukraine conflict.\"Yes, I think that Vladimir Putin must also understand that the Atlantic alliance is a nuclear alliance.\nA version of this story appeared in CNN's What Matters newsletter. To get it in your inbox, sign up for free here.\n(CNN)Europe woke up to a major war on Thursday after Russian President Vladimir Putin launched a violent, multipronged invasion of Ukraine, the democracy that sits between NATO countries and Russia.\nNow that it is clear Putin will sacrifice lives and Russian wealth to reconstitute parts of the old Soviet Union, European and US troops are scrambling to fortify the wall of NATO countries that borders Ukraine -- and the fear that he could move farther, past Ukraine, is now very real.\nOn a continent that spent decades as the front line of the Cold War in a standoff over ideology between nuclear powers, this new war seems like a return to the sort of conventional warfare that marked Europe before the world wars, when countries did battle and tested their alliances.\nNo one in recent weeks has claimed to know what's in Putin's head. But few guessed he would so boldly try to take over Ukraine.\nUS markets rebounded, while Russia's haven't yet. Egan noted that the stock market dropped in the morning after news of the attacks on Ukraine, but then rebounded after Biden announced sanctions.\nRussia's stock market, on the other hand, lost a third of its value. The value of the ruble also tumbled.\"There are some real concerns from investors about Russia becoming a pariah state at this point,\" he said.Consider the unlikely nightmare scenario. I talked to Tom Collina, policy director at the Ploughshares Fund -- which pushes to eliminate the dangers posed by nuclear weapons -- about what it means for the US and Russia, the world's two top nuclear countries, to be in a standoff.\nHe said Putin's new demeanor means the world needs to view him differently. The worst possible scenario, which is very unlikely, is the US and Russia in an armed conflict and a miscalculation triggering nuclear war.\"I think all bets are off as to knowing what he's going to do next,\" Collina said.\nNobody wants to trigger such a scenario, but with nuclear powers in conflict, there is major concern.\"Even if they don't want to get into a nuclear conflict, they could by accident or miscalculation,\" Collina said. \"In the fog of war, things can happen that no one ever wanted to happen.\"\nThere is already nuclear talk. Ukraine used to house many of the Soviet Union's nuclear weapons but gave them up in 1994 in exchange for a security guarantee, known as the Budapest Memorandum, from the US, the United Kingdom and Russia. That promise was clearly violated this week.\nPutin made up a conspiracy theory that the US and Ukraine were plotting to place nuclear weapons back in Ukraine as a pretext for his invasion.\nFrench Foreign Minister Jean-Yves Le Drian said Thursday on French television, according to Reuters, that his country viewed some of Putin's recent comments as a threat to use nuclear weapons in the Ukraine conflict.\"Yes, I think that Vladimir Putin must also understand that the Atlantic alliance is a nuclear alliance.";
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        bytes32 returnContentHash = _publish(content, true);
        assertEq(contentHash, returnContentHash);
    }

    /**
     * Set title, description, fork price and publish new content
     * in one transaction
     */
    function testMulticall() public {
        _claimToTraveloggersOwner();

        bytes[] memory data = new bytes[](4);

        // title
        string memory title = "Sit deserunt nulla aliqua ex nisi";
        data[0] = abi.encodeWithSignature("setTitle(uint256,string)", CLAIM_TOKEN_START_ID, title);

        // description
        string
            memory description = "Deserunt proident dolor id Lorem pariatur irure adipisicing labore labore aute sunt aliquip culpa consectetur laboris.";
        data[1] = abi.encodeWithSignature("setDescription(uint256,string)", CLAIM_TOKEN_START_ID, description);

        // fork price
        uint256 forkPrice = 0.122 ether;
        data[2] = abi.encodeWithSignature("setForkPrice(uint256,uint256)", CLAIM_TOKEN_START_ID, forkPrice);

        // publish
        string
            memory content = "Fugiat proident irure et mollit quis occaecat labore cupidatat ut aute tempor esse exercitation eiusmod. Do commodo incididunt quis exercitation laboris adipisicing nisi. Magna aliquip aute mollit id aliquip incididunt sint ea laborum mollit eiusmod do aliquip aute. Enim ea eiusmod pariatur mollit pariatur irure consectetur anim. Proident elit nisi ea laboris ad reprehenderit. Consectetur consequat excepteur duis tempor nulla id in commodo occaecat. Excepteur quis nostrud velit exercitation ut ullamco tempor nulla non. Occaecat laboris anim labore ut adipisicing nisi. Sit enim dolor eiusmod ipsum nulla quis aliqua reprehenderit ea. Lorem sit tempor consequat magna Lorem deserunt duis.";
        data[3] = abi.encodeWithSignature("publish(uint256,string)", CLAIM_TOKEN_START_ID, content);

        // call
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        vm.prank(TRAVELOGGERS_OWNER);
        vm.expectEmit(true, true, false, false);
        emit SetTitle(CLAIM_TOKEN_START_ID, title);
        vm.expectEmit(true, true, false, false);
        emit SetDescription(CLAIM_TOKEN_START_ID, description);
        vm.expectEmit(true, true, false, false);
        emit SetForkPrice(CLAIM_TOKEN_START_ID, forkPrice);
        vm.expectEmit(true, true, true, false);
        emit Content(TRAVELOGGERS_OWNER, contentHash, content);
        vm.expectEmit(true, true, false, false);
        emit Publish(CLAIM_TOKEN_START_ID, contentHash);
        logbook.multicall(data);
    }

    /**
     * Donate, Fork
     */
    function testDonate(uint96 amount) public {
        _claimToTraveloggersOwner();

        // donate
        vm.deal(PUBLIC_SALE_MINTER, amount);
        vm.prank(PUBLIC_SALE_MINTER);
        if (amount > 0) {
            // uint256 contractBalance = address(this).balance;
            vm.expectEmit(true, true, true, false);
            emit Donate(CLAIM_TOKEN_START_ID, PUBLIC_SALE_MINTER, amount);
            logbook.donate{value: amount}(CLAIM_TOKEN_START_ID);
            // assertEq(address(this).balance, contractBalance + amount);
        } else {
            vm.expectRevert(abi.encodePacked(bytes4(keccak256("ZeroAmount()"))));
            logbook.donate{value: amount}(CLAIM_TOKEN_START_ID);
        }

        // no logbook
        vm.deal(PUBLIC_SALE_MINTER, 1 ether);
        vm.prank(PUBLIC_SALE_MINTER);
        vm.expectRevert(abi.encodePacked(bytes4(keccak256("TokenNotExists()"))));
        logbook.donate{value: 1 ether}(CLAIM_TOKEN_START_ID + 1);
    }

    function testDonateWithCommission(uint96 amount, uint96 bps) public {
        _claimToTraveloggersOwner();

        bool isInvalidBPS = bps > _ROYALTY_BPS_COMMISSION_MAX;

        // donate
        vm.deal(PUBLIC_SALE_MINTER, amount);
        vm.prank(PUBLIC_SALE_MINTER);
        if (amount > 0) {
            if (isInvalidBPS) {
                vm.expectRevert(abi.encodeWithSignature("InvalidBPS(uint256,uint256)", 0, 2000));
            } else {
                vm.expectEmit(true, true, true, false);
                emit Donate(CLAIM_TOKEN_START_ID, PUBLIC_SALE_MINTER, amount);
            }

            logbook.donateWithCommission{value: amount}(CLAIM_TOKEN_START_ID, FRONTEND_OPERATOR, bps);
        } else {
            vm.expectRevert(abi.encodePacked(bytes4(keccak256("ZeroAmount()"))));
            logbook.donateWithCommission{value: amount}(CLAIM_TOKEN_START_ID, FRONTEND_OPERATOR, bps);
        }

        // no logbook
        vm.deal(PUBLIC_SALE_MINTER, 1 ether);
        vm.prank(PUBLIC_SALE_MINTER);
        vm.expectRevert(abi.encodePacked(bytes4(keccak256("TokenNotExists()"))));
        logbook.donateWithCommission{value: 1 ether}(CLAIM_TOKEN_START_ID + 1, FRONTEND_OPERATOR, bps);
    }

    function testFork(uint96 amount, string calldata content) public {
        _claimToTraveloggersOwner();

        // no logbook
        vm.deal(PUBLIC_SALE_MINTER, amount);
        vm.prank(PUBLIC_SALE_MINTER);
        vm.expectRevert(abi.encodePacked(bytes4(keccak256("TokenNotExists()"))));
        logbook.fork{value: amount}(CLAIM_TOKEN_START_ID + 1, 1);

        // no content
        vm.deal(PUBLIC_SALE_MINTER, amount);
        vm.prank(PUBLIC_SALE_MINTER);
        vm.expectRevert(abi.encodeWithSignature("InsufficientLogs(uint32)", 0));
        logbook.fork{value: amount}(CLAIM_TOKEN_START_ID, 1);

        _publish(content, true);

        // value too small
        if (amount > 1) {
            _setForkPrice(amount);
            vm.deal(PUBLIC_SALE_MINTER, amount);
            vm.prank(PUBLIC_SALE_MINTER);
            vm.expectRevert(abi.encodeWithSignature("InsufficientAmount(uint256,uint256)", amount / 2, amount));
            logbook.fork{value: amount / 2}(CLAIM_TOKEN_START_ID, 1);
        }

        // fork
        _setForkPrice(amount);
        // uint256 contractBalance = address(this).balance;
        vm.deal(PUBLIC_SALE_MINTER, amount);
        vm.prank(PUBLIC_SALE_MINTER);
        vm.expectEmit(true, true, true, true);
        emit Fork(CLAIM_TOKEN_START_ID, CLAIM_TOKEN_END_ID + 1, PUBLIC_SALE_MINTER, 1, amount);
        logbook.fork{value: amount}(CLAIM_TOKEN_START_ID, 1);
        // assertEq(address(this).balance, contractBalance + amount);
    }

    function testForkRecursively(uint8 forkCount, uint96 forkPrice) public {
        vm.assume(forkCount <= 64);

        _claimToTraveloggersOwner();
        _publish("1234", true);
        _setForkPrice(forkPrice);

        // forks
        address logbookOwner = TRAVELOGGERS_OWNER;
        uint256 nextTokenId = CLAIM_TOKEN_START_ID;
        for (uint32 i = 0; i < forkCount; i++) {
            address prevLogbookOwner = logbookOwner;
            logbookOwner = address(uint160(i + 10000));

            // fork
            vm.deal(logbookOwner, forkPrice);
            vm.prank(logbookOwner);
            nextTokenId = logbook.fork{value: forkPrice}(nextTokenId, 1);

            // append log
            string memory content = Strings.toString(i);
            vm.prank(logbookOwner);
            logbook.publish(nextTokenId, content);

            uint256 feesLogbookOwner = (forkPrice * _ROYALTY_BPS_LOGBOOK_OWNER) / 10000;
            uint256 feesPerLogAuthor = (forkPrice - feesLogbookOwner) / (i + 1);

            // check owner balance
            assertEq(logbook.getBalance(prevLogbookOwner), feesLogbookOwner + feesPerLogAuthor);
        }
        assertEq(logbookOwner, logbook.ownerOf(nextTokenId));

        // check logs
        (bytes32[] memory contentHashes, address[] memory authors) = logbook.getLogs(nextTokenId);
        ILogbook.Book memory book = logbook.getLogbook(nextTokenId);
        assertEq(book.logCount, forkCount + 1);
        assertEq(forkCount + 1, contentHashes.length);
        assertEq(forkCount + 1, authors.length);
    }

    function testForkWithCommission(
        uint96 amount,
        string calldata content,
        uint256 bps
    ) public {
        bool isInvalidBPS = bps > _ROYALTY_BPS_COMMISSION_MAX;

        _claimToTraveloggersOwner();
        _publish(content, true);
        _setForkPrice(amount);

        vm.deal(PUBLIC_SALE_MINTER, amount);
        vm.prank(PUBLIC_SALE_MINTER);

        if (isInvalidBPS) {
            vm.expectRevert(abi.encodeWithSignature("InvalidBPS(uint256,uint256)", 0, 2000));
        } else {
            vm.expectEmit(true, true, true, true);
            emit Fork(CLAIM_TOKEN_START_ID, CLAIM_TOKEN_END_ID + 1, PUBLIC_SALE_MINTER, 1, amount);
        }

        uint256 newTokenId = logbook.forkWithCommission{value: amount}(CLAIM_TOKEN_START_ID, 1, FRONTEND_OPERATOR, bps);

        if (!isInvalidBPS) {
            // get tokenURI
            logbook.tokenURI(newTokenId);
        }
    }

    /**
     * Split Royalty, Withdraw
     */
    function testSplitRoyalty(
        uint8 logCount,
        uint8 endAt,
        uint96 forkPrice
    ) public {
        vm.assume(logCount <= 64);

        _claimToTraveloggersOwner();
        _setForkPrice(forkPrice);

        // append logs
        address logbookOwner = TRAVELOGGERS_OWNER;
        address firstAuthor;
        for (uint32 i = 0; i < logCount; i++) {
            // transfer to new owner
            address currentOwner = logbook.ownerOf(CLAIM_TOKEN_START_ID);
            logbookOwner = address(uint160(i + 10000));
            assertTrue(currentOwner != logbookOwner);

            if (i == 0) {
                firstAuthor = logbookOwner;
            }

            vm.deal(currentOwner, forkPrice);
            vm.prank(currentOwner);
            logbook.transferFrom(currentOwner, logbookOwner, CLAIM_TOKEN_START_ID);

            // append log
            string memory content = Strings.toString(i);
            vm.deal(logbookOwner, forkPrice);
            vm.prank(logbookOwner);
            logbook.publish(CLAIM_TOKEN_START_ID, content);
        }
        assertEq(logbookOwner, logbook.ownerOf(CLAIM_TOKEN_START_ID));

        // check logs
        (bytes32[] memory contentHashes, address[] memory authors) = logbook.getLogs(CLAIM_TOKEN_START_ID);
        ILogbook.Book memory book = logbook.getLogbook(CLAIM_TOKEN_START_ID);
        assertEq(book.logCount, logCount);
        assertEq(logCount, contentHashes.length);
        assertEq(logCount, authors.length);

        uint32 maxEndAt = uint32(book.contentHashes.length);
        vm.deal(PUBLIC_SALE_MINTER, forkPrice);
        vm.prank(PUBLIC_SALE_MINTER);

        // fork
        if (logCount <= 0 || endAt <= 0 || maxEndAt < endAt) {
            vm.expectRevert(abi.encodeWithSignature("InsufficientLogs(uint32)", logCount));
            logbook.fork{value: forkPrice}(CLAIM_TOKEN_START_ID, endAt);
            return;
        } else {
            vm.expectEmit(true, true, true, true);
            emit Fork(CLAIM_TOKEN_START_ID, CLAIM_TOKEN_END_ID + 1, PUBLIC_SALE_MINTER, endAt, forkPrice);
        }

        uint256 newTokenId = logbook.fork{value: forkPrice}(CLAIM_TOKEN_START_ID, endAt);

        // get tokenURI
        logbook.tokenURI(newTokenId);

        // check log count
        ILogbook.Book memory newBook = logbook.getLogbook(newTokenId);
        assertEq(book.logCount - maxEndAt + endAt, newBook.logCount);

        // check content hashes
        (bytes32[] memory newContentHashes, ) = logbook.getLogs(newTokenId);
        assertEq(keccak256(abi.encodePacked(Strings.toString(uint32(0)))), newContentHashes[0]);

        assertEq(keccak256(abi.encodePacked(Strings.toString(uint32(endAt - 1)))), newContentHashes[endAt - 1]);

        // check balances
        uint256 feesLogbookOwner = (forkPrice * _ROYALTY_BPS_LOGBOOK_OWNER) / 10000;
        uint256 feesPerLogAuthor = (forkPrice - feesLogbookOwner) / endAt;

        if (logCount == endAt) {
            // logbook owner
            assertEq(logbook.getBalance(logbookOwner), feesLogbookOwner + feesPerLogAuthor);
        } else {
            // logbook owner
            assertEq(logbook.getBalance(logbookOwner), feesLogbookOwner);

            // first author
            if (endAt > 2) {
                uint256 firstAuthorBalance = logbook.getBalance(firstAuthor);
                assertEq(firstAuthorBalance, feesPerLogAuthor);
            }
        }
    }

    function testWithdraw() public {
        uint256 donationValue = 3.13 ether;
        uint32 logCount = 64;

        _claimToTraveloggersOwner();

        // append logs
        for (uint32 i = 0; i < logCount; i++) {
            // transfer to new owner
            address currentOwner = logbook.ownerOf(CLAIM_TOKEN_START_ID);
            address newOwner = address(uint160(i + 10000));
            assertTrue(currentOwner != newOwner);
            vm.prank(currentOwner);
            logbook.transferFrom(currentOwner, newOwner, CLAIM_TOKEN_START_ID);

            // append log
            string memory content = string(abi.encodePacked(i));
            vm.deal(newOwner, donationValue);
            vm.prank(newOwner);
            logbook.publish(CLAIM_TOKEN_START_ID, content);
        }

        // uint256 contractBalance = address(this).balance;

        // donate
        vm.deal(PUBLIC_SALE_MINTER, donationValue);
        vm.prank(PUBLIC_SALE_MINTER);
        vm.expectEmit(true, true, true, false);
        emit Donate(CLAIM_TOKEN_START_ID, PUBLIC_SALE_MINTER, donationValue);
        logbook.donate{value: donationValue}(CLAIM_TOKEN_START_ID);

        // logbook owner withdrawl
        address owner = address(uint160(logCount - 1 + 10000));
        uint256 feesLogbookOwner = (donationValue * _ROYALTY_BPS_LOGBOOK_OWNER) / 10000;
        uint256 feesPerLogAuthor = (donationValue - feesLogbookOwner) / logCount;
        uint256 ownerBalance = logbook.getBalance(owner);
        assertEq(ownerBalance, feesLogbookOwner + feesPerLogAuthor);

        uint256 ownerWalletBalance = owner.balance;
        vm.prank(owner);
        vm.expectEmit(true, true, false, false);
        emit Withdraw(owner, ownerBalance);
        logbook.withdraw();
        assertEq(owner.balance, ownerWalletBalance + ownerBalance);
        assertEq(logbook.getBalance(owner), 0);

        // uint256 contractBalanceAfterOwnerWithdraw = address(this).balance;
        // assertEq(contractBalanceAfterOwnerWithdraw, contractBalance - ownerWalletBalance - ownerBalance);

        // previous author withdrawl
        address secondLastOwner = address(uint160(logCount - 2 + 10000));
        uint256 secondLastOwnerBalance = logbook.getBalance(secondLastOwner);
        assertEq(secondLastOwnerBalance, feesPerLogAuthor);

        uint256 secondLastOwnerWalletBalance = secondLastOwner.balance;
        vm.prank(secondLastOwner);
        vm.expectEmit(true, true, false, false);
        emit Withdraw(secondLastOwner, secondLastOwnerBalance);
        logbook.withdraw();
        assertEq(secondLastOwner.balance, secondLastOwnerWalletBalance + secondLastOwnerBalance);
        assertEq(logbook.getBalance(secondLastOwner), 0);
        // assertEq(address(this).balance, secondLastOwnerWalletBalance - feesPerLogAuthor);
    }
}
