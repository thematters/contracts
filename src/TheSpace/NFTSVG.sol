//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library NFTSVG {
    struct SVGParams {
        string[16] colors;
        uint256 tokenId;
    }

    function generateSVG(SVGParams memory params) internal pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<svg width="1200" height="1200" xmlns="http://www.w3.org/2000/svg"><g fill="none" fill-rule="evenodd"><g fill-rule="nonzero">',
                // generateTile(params, "0 844 0 905.99 85.0175 844", 0),
                // generateTile(params, "245.616 844 85.0175 844 0 905.99 0 906.31 160.15 906.31", 1),
                // generateTile(params, "0 906.31 0 992.46 41.985 992.46 160.15 906.31", 2),
                // generateTile(params, "41.985 992.46 0 992.46 0 1023.08", 3),
                // generateTile(params, "0 1132 0 1200 53.0374 1200 113.726 1132", 4),
                // generateTile(params, "370.773 844 245.616 844 160.149 906.31 315.152 906.31", 5),
                // generateTile(params, "160.149 906.31 41.9849 992.46 238.264 992.46 315.152 906.31", 6),
                // generateTile(params, "41.985 992.46 0 1023.08 0 1132 113.726 1132 238.264 992.46", 7),
                // generateTile(params, "511.541 844 370.773 844 315.152 906.31 483.92 906.31", 8),
                // generateTile(params, "315.152 906.31 238.264 992.46 445.726 992.46 483.92 906.31", 9),
                // generateTile(params, "113.725 1132 53.0371 1200 353.715 1200 383.86 1132", 10),
                // generateTile(params, "691.521 844 511.541 844 483.92 906.31 719.152 906.31", 11),
                // generateTile(params, "483.92 906.31 445.726 992.46 757.337 992.46 719.152 906.31", 12),
                // generateTile(params, "445.726 992.46 383.86 1132 819.202 1132 757.337 992.46", 13),
                // generateTile(params, "383.86 1132 353.716 1200 849.347 1200 819.202 1132", 14),
                // generateTile(params, "757.336 992.46 819.202 1132 1081.53 1132 956.987 992.46", 15),
                // generateTile(params, "824.479 844 691.521 844 719.152 906.31 880.1 906.31", 16),
                // generateTile(params, "719.152 906.31 757.337 992.46 956.988 992.46 880.1 906.31", 17),
                // generateTile(params, "819.202 1132 849.347 1200 1142.21 1200 1081.53 1132", 18),
                // generateTile(params, "1200 844 1100.26 844 1185.73 906.31 1200 906.31", 19),
                // generateTile(params, "1200 906.31 1185.73 906.31 1200 916.72", 20),
                // generateTile(params, "1200 992.46 1153.27 992.46 1200 1026.54", 21),
                // generateTile(params, "1100.26 844 949.636 844 1035.1 906.31 1185.73 906.31", 22),
                // generateTile(params, "1035.1 906.31 1153.27 992.46 1200 992.46 1200 916.72 1185.73 906.31", 23),
                // generateTile(params, "949.636 844 824.479 844 880.1 906.31 1035.1 906.31", 24),
                // generateTile(params, "880.1 906.31 956.987 992.46 1153.27 992.46 1035.1 906.31", 25),
                // generateTile(params, "956.987 992.46 1081.53 1132 1200 1132 1200 1026.54 1153.27 992.46", 26),
                // generateTile(params, "1081.53 1132 1142.21 1200 1200 1200 1200 1132", 27),
                '</g><image width="1200" height="1200" x="0" y="0" xlink:href="',
                "https://picsum.photos/1200/1200",
                '" />',
                "</g></svg>"
            )
        );
    }

    function generateTile(
        SVGParams memory params,
        string memory points,
        uint256 random
    ) internal pure returns (string memory svg) {
        string[16] memory randomColors = _shuffleColors(params.colors, params.tokenId + random);

        svg = string(
            abi.encodePacked(
                '<polygon id="Path" fill="',
                "red",
                '" fill-rule="nonzero" points="',
                points,
                '">',
                '<animate calcMode="discrete" attributeName="fill" values="',
                randomColors[0],
                ";",
                randomColors[1],
                ";",
                randomColors[2],
                ";",
                randomColors[3],
                ";",
                randomColors[4],
                '" keytimes="0.2;0.5;0.8;1.1;1.2" dur="1.2s" repeatCount="indefinite" />',
                "</polygon>"
            )
        );
    }

    function _shuffleColors(string[16] memory array, uint256 random) private pure returns (string[16] memory) {
        for (uint256 i = 0; i < array.length; i++) {
            uint256 n = i + (uint256(keccak256(abi.encodePacked(random))) % (array.length - i));
            string memory temp = array[n];
            array[n] = array[i];
            array[i] = temp;
        }

        return array;
    }
}
