//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library NFTSVG {
    struct SVGParams {
        uint256 tokenId;
    }

    function generateSVG(SVGParams memory params) public pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<svg width="1200" height="1200" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><g fill="none" fill-rule="evenodd"><g fill-rule="nonzero">',
                _generateTiles(params),
                '</g><image width="1200" height="1200" x="0" y="0" xlink:href="',
                "https://picsum.photos/1200/1200",
                '" />',
                "</g></svg>"
            )
        );
    }

    function _generateTiles(SVGParams memory params) private pure returns (string memory svg) {
        string[28] memory points = [
            "0 844 0 905.99 85.0175 844",
            "245.616 844 85.0175 844 0 905.99 0 906.31 160.15 906.31",
            "0 906.31 0 992.46 41.985 992.46 160.15 906.31",
            "41.985 992.46 0 992.46 0 1023.08",
            "0 1132 0 1200 53.0374 1200 113.726 1132",
            "370.773 844 245.616 844 160.149 906.31 315.152 906.31",
            "160.149 906.31 41.9849 992.46 238.264 992.46 315.152 906.31",
            "41.985 992.46 0 1023.08 0 1132 113.726 1132 238.264 992.46",
            "511.541 844 370.773 844 315.152 906.31 483.92 906.31",
            "315.152 906.31 238.264 992.46 445.726 992.46 483.92 906.31",
            "113.725 1132 53.0371 1200 353.715 1200 383.86 1132",
            "691.521 844 511.541 844 483.92 906.31 719.152 906.31",
            "483.92 906.31 445.726 992.46 757.337 992.46 719.152 906.31",
            "445.726 992.46 383.86 1132 819.202 1132 757.337 992.46",
            "383.86 1132 353.716 1200 849.347 1200 819.202 1132",
            "757.336 992.46 819.202 1132 1081.53 1132 956.987 992.46",
            "824.479 844 691.521 844 719.152 906.31 880.1 906.31",
            "719.152 906.31 757.337 992.46 956.988 992.46 880.1 906.31",
            "819.202 1132 849.347 1200 1142.21 1200 1081.53 1132",
            "1200 844 1100.26 844 1185.73 906.31 1200 906.31",
            "1200 906.31 1185.73 906.31 1200 916.72",
            "1200 992.46 1153.27 992.46 1200 1026.54",
            "1100.26 844 949.636 844 1035.1 906.31 1185.73 906.31",
            "1035.1 906.31 1153.27 992.46 1200 992.46 1200 916.72 1185.73 906.31",
            "949.636 844 824.479 844 880.1 906.31 1035.1 906.31",
            "880.1 906.31 956.987 992.46 1153.27 992.46 1035.1 906.31",
            "956.987 992.46 1081.53 1132 1200 1132 1200 1026.54 1153.27 992.46",
            "1081.53 1132 1142.21 1200 1200 1200 1200 1132"
        ];

        string[16] memory colors = [
            "#000000",
            "#FFFFFF",
            "#D4D7D9",
            "#898D90",
            "#784102",
            "#D26500",
            "#FF8A00",
            "#FFDE2F",
            "#8DE763",
            "#159800",
            "#58EAF4",
            "#059DF2",
            "#034CBA",
            "#9503C9",
            "#D90041",
            "#FF9FAB"
        ];
        uint256 len = points.length;

        for (uint256 i = 0; i < len; i++) {
            uint256[] memory shuffle = _shuffle(16, params.tokenId + i);

            svg = string(
                abi.encodePacked(
                    svg,
                    '<polygon fill-rule="nonzero" points="',
                    points[i],
                    '"><animate calcMode="discrete" attributeName="fill" values="',
                    colors[shuffle[0] - 1],
                    ";",
                    colors[shuffle[1] - 1],
                    ";",
                    colors[shuffle[2] - 1],
                    ";",
                    colors[shuffle[3] - 1],
                    ";",
                    colors[shuffle[4] - 1],
                    '" keytimes="0.2;0.5;0.8;1.1;1.2" dur="1.2s" repeatCount="indefinite" /></polygon>'
                )
            );
        }
    }

    // @dev https://gist.github.com/cleanunicorn/d27484a2488e0eecec8ce23a0ad4f20b
    function _shuffle(uint256 size, uint256 entropy) private pure returns (uint256[] memory) {
        uint256[] memory result = new uint256[](size);

        // Initialize array.
        for (uint256 i = 0; i < size; i++) {
            result[i] = i + 1;
        }

        // Set the initial randomness based on the provided entropy.
        bytes32 random = keccak256(abi.encodePacked(entropy));

        // Set the last item of the array which will be swapped.
        uint256 last_item = size - 1;

        // We need to do `size - 1` iterations to completely shuffle the array.
        for (uint256 i = 1; i < size - 1; i++) {
            // Select a number based on the randomness.
            uint256 selected_item = uint256(random) % last_item;

            // Swap items `selected_item <> last_item`.
            uint256 aux = result[last_item];
            result[last_item] = result[selected_item];
            result[selected_item] = aux;

            // Decrease the size of the possible shuffle
            // to preserve the already shuffled items.
            // The already shuffled items are at the end of the array.
            last_item--;

            // Generate new randomness.
            random = keccak256(abi.encodePacked(random));
        }

        return result;
    }
}
