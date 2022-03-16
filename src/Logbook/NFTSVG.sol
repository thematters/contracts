//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library NFTSVG {
    struct SVGParams {
        uint32 logCount;
        uint32 transferCount;
        uint160 createdAt;
        uint256 tokenId;
    }

    function generateSVG(SVGParams memory params) internal pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<svg width="800" height="800" xmlns="http://www.w3.org/2000/svg"><g fill="none" fill-rule="evenodd">',
                generateSVGBackground(params),
                generateSVGPathsA(params),
                generateSVGPathsB(params),
                generateSVGTexts(params),
                "</g></svg>"
            )
        );
    }

    function generateSVGBackground(SVGParams memory params) internal pure returns (string memory svg) {
        string memory colorBackground = params.logCount < 10 ? "#F3F1EA" : "#41403F";

        svg = string(abi.encodePacked('<path d="M0 0h800v800H0z" fill="', colorBackground, '"/>'));
    }

    function generateSVGPathsA(SVGParams memory params) internal pure returns (string memory svg) {
        string memory color = string(
            abi.encodePacked(
                "rgba(",
                Strings.toString(uint8((params.createdAt * _max(params.logCount, 1) * 10) % 256)),
                ",",
                Strings.toString(uint8((params.createdAt * _max(params.transferCount, 1) * 80) % 256)),
                ",",
                Strings.toString(uint8(params.tokenId % 256)),
                ",0.5)"
            )
        );

        string[7] memory paths;
        paths[0] = string(
            abi.encodePacked(
                '<path d="M128.19 145a30 30 0 0 0-30 30v4.47a30 30 0 0 0 30 30h18.13a30 30 0 0 1 30 30v17.8a30 30 0 0 0 30 30h.91a30 30 0 0 0 30-30V175a30 30 0 0 0-30-30h-79.04Z" fill="',
                color,
                '"/>'
            )
        );
        paths[1] = string(
            abi.encodePacked(
                '<path d="M470.53 334.64a30 30 0 0 0-30-30h-4.4a30 30 0 0 0-30 30v19.76a30 30 0 0 1-30 30H358.4a30 30 0 0 0-30 30v2.17a30 30 0 0 0 30 30h82.12a30 30 0 0 0 30-30v-81.93Z" fill="',
                color,
                '"/>'
            )
        );
        paths[2] = string(
            abi.encodePacked(
                '<path d="M362.26 368.56a30 30 0 0 0 30-30v-4.47a30 30 0 0 0-30-30h-18.13a30 30 0 0 1-30-30v-17.8a30 30 0 0 0-30-30h-.9a30 30 0 0 0-30 30v82.27a30 30 0 0 0 30 30h79.03Z" fill="',
                color,
                '"/>'
            )
        );
        paths[3] = string(
            abi.encodePacked(
                '<path d="M591.7 368.56a30 30 0 0 1-30-30v-4.47a30 30 0 0 1 30-30h18.14a30 30 0 0 0 30-30v-17.8a30 30 0 0 1 30-30h.9a30 30 0 0 1 30 30v82.27a30 30 0 0 1-30 30h-79.03ZM591.7 678a30 30 0 0 1-30-30v-4.47a30 30 0 0 1 30-30h18.14a30 30 0 0 0 30-30v-17.8a30 30 0 0 1 30-30h.9a30 30 0 0 1 30 30V648a30 30 0 0 1-30 30h-79.03Z" fill="',
                color,
                '"/>'
            )
        );
        paths[4] = string(
            abi.encodePacked(
                '<path d="M210 381.01h-5.84a30 30 0 0 0-30 30v3.6a30 30 0 0 0 30 30H210a30 30 0 0 0 30-30V411a30 30 0 0 0-30-30ZM134.02 613.75h-5.83a30 30 0 0 0-30 30v3.6a30 30 0 0 0 30 30h5.83a30 30 0 0 0 30-30v-3.6a30 30 0 0 0-30-30Z" fill="',
                color,
                '"/>'
            )
        );
        paths[5] = string(
            abi.encodePacked(
                '<path d="M467.91 182.53v-7.2a30 30 0 0 0-30-30H437a30 30 0 0 0-30 30v7.2a30 30 0 0 0 30 30h.91a30 30 0 0 0 30-30Z" fill="',
                color,
                '"/>'
            )
        );
        paths[6] = string(
            abi.encodePacked(
                '<path d="M624.44 257.26v-81.93a30 30 0 0 0-30-30h-.9a30 30 0 0 0-30 30v81.93a30 30 0 0 0 30 30h.9a30 30 0 0 0 30-30ZM437.16 601.3h81.8a30 30 0 0 0 30-30v-5.4a30 30 0 0 0-30-30h-81.8a30 30 0 0 0-30 30v5.4a30 30 0 0 0 30 30ZM546.5 493.28v-81.94a30 30 0 0 0-30-30h-.9a30 30 0 0 0-30 30v81.94a30 30 0 0 0 30 30h.9a30 30 0 0 0 30-30ZM314 648v-81.94a30 30 0 0 0-30-30h-.91a30 30 0 0 0-30 30V648a30 30 0 0 0 30 30h.9a30 30 0 0 0 30-30Z" fill="',
                color,
                '"/>'
            )
        );

        svg = string(abi.encodePacked(paths[0], paths[1], paths[2], paths[3], paths[4], paths[5], paths[6]));
    }

    function generateSVGPathsB(SVGParams memory params) internal pure returns (string memory svg) {
        string memory color = string(
            abi.encodePacked(
                "rgb(",
                Strings.toString(uint8((params.createdAt * _max(params.logCount, 1) * 20) % 256)),
                ",",
                Strings.toString(uint8((params.createdAt * _max(params.transferCount, 1) * 40) % 256)),
                ",",
                Strings.toString(uint8(params.tokenId % 256)),
                ")"
            )
        );

        string[6] memory paths;
        paths[0] = string(
            abi.encodePacked(
                '<path d="M283.22 145a30 30 0 0 0-30 30v4.47a30 30 0 0 0 30 30h18.14a30 30 0 0 1 30 30v17.8a30 30 0 0 0 30 30h.9a30 30 0 0 0 30-30V175a30 30 0 0 0-30-30h-79.04ZM670.75 524.6a30 30 0 0 0 30-30v-4.48a30 30 0 0 0-30-30H652.6a30 30 0 0 1-30-30v-17.8a30 30 0 0 0-30-30h-.9a30 30 0 0 0-30 30v82.27a30 30 0 0 0 30 30h79.04ZM434.96 678a30 30 0 0 0 30-30v-4.47a30 30 0 0 0-30-30h-18.13a30 30 0 0 1-30-30v-17.8a30 30 0 0 0-30-30h-.9a30 30 0 0 0-30 30V648a30 30 0 0 0 30 30h79.03ZM549.13 175.33a30 30 0 0 0-30-30h-4.41a30 30 0 0 0-30 30v19.76a30 30 0 0 1-30 30H437a30 30 0 0 0-30 30v2.17a30 30 0 0 0 30 30h82.13a30 30 0 0 0 30-30v-81.93Z" fill="',
                color,
                '"/>'
            )
        );
        paths[1] = string(
            abi.encodePacked(
                '<path d="M128 535.74a30 30 0 0 0-30 30v4.47a30 30 0 0 0 30 30h18.14a30 30 0 0 1 30 30V648a30 30 0 0 0 30 30h.9a30 30 0 0 0 30-30v-82.26a30 30 0 0 0-30-30H128ZM362.26 524.6a30 30 0 0 0 30-30v-4.48a30 30 0 0 0-30-30h-18.13a30 30 0 0 1-30-30v-17.8a30 30 0 0 0-30-30h-.9a30 30 0 0 0-30 30v82.27a30 30 0 0 0 30 30h79.03ZM207.04 523.28a30 30 0 0 0 30-30v-4.47a30 30 0 0 0-30-30H188.9a30 30 0 0 1-30-30V411a30 30 0 0 0-30-30h-.9a30 30 0 0 0-30 30v82.27a30 30 0 0 0 30 30h79.04Z" fill="',
                color,
                '"/>'
            )
        );
        paths[2] = string(
            abi.encodePacked(
                '<path d="M134.02 226.3h-5.83a30 30 0 0 0-30 30v.96a30 30 0 0 0 30 30h5.83a30 30 0 0 0 30-30v-.97a30 30 0 0 0-30-30Z" fill="',
                color,
                '"/>'
            )
        );
        paths[3] = string(
            abi.encodePacked(
                '<path d="M597.07 536.4h-5.83a30 30 0 0 0-30 30v3.58a30 30 0 0 0 30 30h5.83a30 30 0 0 0 30-30v-3.59a30 30 0 0 0-30-30ZM519.13 613.75h-5.83a30 30 0 0 0-30 30v3.6a30 30 0 0 0 30 30h5.83a30 30 0 0 0 30-30v-3.6a30 30 0 0 0-30-30Z" fill="',
                color,
                '"/>'
            )
        );
        paths[4] = string(
            abi.encodePacked(
                '<path d="M470.53 493.28v-4.25a30 30 0 0 0-30-30h-.91a30 30 0 0 0-30 30v4.25a30 30 0 0 0 30 30h.91a30 30 0 0 0 30-30ZM700.42 182.53v-7.2a30 30 0 0 0-30-30h-.91a30 30 0 0 0-30 30v7.2a30 30 0 0 0 30 30h.9a30 30 0 0 0 30-30ZM700.42 419.2V412a30 30 0 0 0-30-30h-7.13a30 30 0 0 0-30 30v7.2a30 30 0 0 0 30 30h7.13a30 30 0 0 0 30-30ZM546.5 341.18v-7.2a30 30 0 0 0-30-30h-.9a30 30 0 0 0-30 30v7.2a30 30 0 0 0 30 30h.9a30 30 0 0 0 30-30Z" fill="',
                color,
                '"/>'
            )
        );
        paths[5] = string(
            abi.encodePacked(
                '<path d="M128.03 368.07h81.8a30 30 0 0 0 30-30v-.97a30 30 0 0 0-30-30h-81.8a30 30 0 0 0-30 30v.97a30 30 0 0 0 30 30Z" fill="',
                color,
                '"/>'
            )
        );

        svg = string(abi.encodePacked(paths[0], paths[1], paths[2], paths[3], paths[4], paths[5]));
    }

    function generateSVGTexts(SVGParams memory params) internal pure returns (string memory svg) {
        string memory colorBackground = params.logCount < 10 ? "#F3F1EA" : "#41403F";
        string memory colorText = params.logCount < 10 ? "#333" : "#fff";

        string[3] memory texts;

        // title
        texts[0] = string(
            abi.encodePacked(
                '<text fill="',
                colorText,
                '" font-family="Roboto, Tahoma-Bold, Tahoma" font-size="48" font-weight="bold"><tspan x="99.3" y="105.4">LOGBOOK</tspan></text>',
                '<path stroke="',
                colorText,
                '" stroke-width="8" d="M387 88h314M99 718h602"/>'
            )
        );

        // metadata
        string memory numbers = string(
            abi.encodePacked(
                "Logs/",
                Strings.toString(params.logCount),
                "    Transfers/",
                Strings.toString(params.transferCount - 1),
                "    ID/",
                Strings.toString(params.tokenId)
            )
        );

        uint256 len = bytes(numbers).length;
        string memory placeholders;
        for (uint256 i = 0; i < len; i++) {
            placeholders = string(abi.encodePacked(placeholders, "g"));
        }
        texts[1] = string(
            abi.encodePacked(
                '<text stroke="',
                colorBackground,
                '" stroke-width="20" font-family="Roboto, Tahoma-Bold, Tahoma" font-size="18" font-weight="bold" fill="',
                colorText,
                '"><tspan x="98" y="724.2">',
                placeholders,
                "</tspan></text>"
            )
        );
        texts[2] = string(
            abi.encodePacked(
                '<text fill="',
                colorText,
                '" font-family="Roboto, Tahoma-Bold, Tahoma" font-size="18" font-weight="bold" xml:space="preserve"><tspan x="98" y="724.2">',
                numbers,
                "</tspan></text>"
            )
        );

        svg = string(abi.encodePacked(texts[0], texts[1], texts[2]));
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
}
