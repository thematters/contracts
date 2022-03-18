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
                "rgb(",
                Strings.toString(uint8((params.createdAt * params.tokenId * _max(params.logCount, 1) * 10) % 256)),
                ",",
                Strings.toString(uint8((params.createdAt * params.transferCount * 80) % 256)),
                ",",
                Strings.toString(uint8(params.tokenId % 256)),
                ")"
            )
        );

        svg = string(
            abi.encodePacked(
                '<path d="M670.7 535.7a30 30 0 0 1 30 30V648a30 30 0 0 1-30 30h-79a30 30 0 0 1-30-30v-4.5a30 30 0 0 1 30-30h18.1a30 30 0 0 0 30-30v-17.8a30 30 0 0 1 30-30h1Zm-386.7.4a30 30 0 0 1 30 30V648a30 30 0 0 1-30 30h-1a30 30 0 0 1-30-30v-82a30 30 0 0 1 30-30Zm-150 77.6a30 30 0 0 1 30 30v3.6a30 30 0 0 1-30 30h-5.8a30 30 0 0 1-30-30v-3.5a30 30 0 0 1 30-30ZM519 536a30 30 0 0 1 30 30v5.4a30 30 0 0 1-30 30h-81.8a30 30 0 0 1-30-30v-5.4a30 30 0 0 1 30-30Zm-2.5-154.6a30 30 0 0 1 30 30v82a30 30 0 0 1-30 30h-.9a30 30 0 0 1-30-30v-82a30 30 0 0 1 30-30Zm-76-76.7a30 30 0 0 1 30 30v82a30 30 0 0 1-30 30h-82.1a30 30 0 0 1-30-30v-2.2a30 30 0 0 1 30-30h17.7a30 30 0 0 0 30-30v-19.8a30 30 0 0 1 30-30ZM210 381a30 30 0 0 1 30 30v3.6a30 30 0 0 1-30 30h-5.8a30 30 0 0 1-30-30V411a30 30 0 0 1 30-30h5.8Zm74.1-154.7a30 30 0 0 1 30 30V274a30 30 0 0 0 30 30h18.2a30 30 0 0 1 30 30v4.5a30 30 0 0 1-30 30h-79a30 30 0 0 1-30-30v-82.3a30 30 0 0 1 30-30Zm386.6 0a30 30 0 0 1 30 30v82.3a30 30 0 0 1-30 30h-79a30 30 0 0 1-30-30V334a30 30 0 0 1 30-30h18.1a30 30 0 0 0 30-30v-17.8a30 30 0 0 1 30-30h1ZM207.2 145a30 30 0 0 1 30 30v82.3a30 30 0 0 1-30 30h-.9a30 30 0 0 1-30-30v-17.8a30 30 0 0 0-30-30h-18.1a30 30 0 0 1-30-30V175a30 30 0 0 1 30-30Zm387.2.3a30 30 0 0 1 30 30v82a30 30 0 0 1-30 30h-.9a30 30 0 0 1-30-30v-82a30 30 0 0 1 30-30Zm-156.5 0a30 30 0 0 1 30 30v7.2a30 30 0 0 1-30 30h-.9a30 30 0 0 1-30-30v-7.2a30 30 0 0 1 30-30Z" fill-opacity=".5" fill="',
                color,
                '"/>'
            )
        );
    }

    function generateSVGPathsB(SVGParams memory params) internal pure returns (string memory svg) {
        string memory color = string(
            abi.encodePacked(
                "rgb(",
                Strings.toString(uint8((params.createdAt * params.tokenId * _max(params.logCount, 1) * 20) % 256)),
                ",",
                Strings.toString(uint8((params.createdAt * params.transferCount * 40) % 256)),
                ",",
                Strings.toString(uint8(params.tokenId % 256)),
                ")"
            )
        );

        svg = string(
            abi.encodePacked(
                '<path d="M356.8 535.7a30 30 0 0 1 30 30v17.8a30 30 0 0 0 30 30H435a30 30 0 0 1 30 30v4.5a30 30 0 0 1-30 30h-79a30 30 0 0 1-30-30v-82.3a30 30 0 0 1 30-30Zm-149.8 0a30 30 0 0 1 30 30V648a30 30 0 0 1-30 30h-.9a30 30 0 0 1-30-30v-17.8a30 30 0 0 0-30-30H128a30 30 0 0 1-30-30v-4.5a30 30 0 0 1 30-30Zm312.1 78a30 30 0 0 1 30 30v3.6a30 30 0 0 1-30 30h-5.8a30 30 0 0 1-30-30v-3.5a30 30 0 0 1 30-30Zm78-77.3a30 30 0 0 1 30 30v3.6a30 30 0 0 1-30 30h-5.9a30 30 0 0 1-30-30v-3.6a30 30 0 0 1 30-30h5.9Zm-4.5-154a30 30 0 0 1 30 30V430a30 30 0 0 0 30 30h18.1a30 30 0 0 1 30 30v4.5a30 30 0 0 1-30 30h-79a30 30 0 0 1-30-30v-82.3a30 30 0 0 1 30-30Zm-308.5 0a30 30 0 0 1 30 30V430a30 30 0 0 0 30 30h18.2a30 30 0 0 1 30 30v4.5a30 30 0 0 1-30 30h-79a30 30 0 0 1-30-30v-82.3a30 30 0 0 1 30-30ZM129 381a30 30 0 0 1 30 30v17.8a30 30 0 0 0 30 30H207a30 30 0 0 1 30 30v4.5a30 30 0 0 1-30 30h-79a30 30 0 0 1-30-30V411a30 30 0 0 1 30-30Zm311.6 78a30 30 0 0 1 30 30v4.3a30 30 0 0 1-30 30h-.9a30 30 0 0 1-30-30V489a30 30 0 0 1 30-30Zm230-77a30 30 0 0 1 30 30v7.2a30 30 0 0 1-30 30h-7.2a30 30 0 0 1-30-30V412a30 30 0 0 1 30-30Zm-154-78a30 30 0 0 1 30 30v7.2a30 30 0 0 1-30 30h-.9a30 30 0 0 1-30-30V334a30 30 0 0 1 30-30ZM209.8 307a30 30 0 0 1 30 30v1a30 30 0 0 1-30 30H128a30 30 0 0 1-30-30v-1a30 30 0 0 1 30-30ZM362.3 145a30 30 0 0 1 30 30v82.3a30 30 0 0 1-30 30h-1a30 30 0 0 1-30-30v-17.8a30 30 0 0 0-30-30h-18a30 30 0 0 1-30-30V175a30 30 0 0 1 30-30Zm156.8.3a30 30 0 0 1 30 30v82a30 30 0 0 1-30 30H437a30 30 0 0 1-30-30V255a30 30 0 0 1 30-30h17.7a30 30 0 0 0 30-30v-19.8a30 30 0 0 1 30-30Zm-385 81a30 30 0 0 1 30 30v1a30 30 0 0 1-30 30h-6a30 30 0 0 1-30-30v-1a30 30 0 0 1 30-30h6Zm536.3-81a30 30 0 0 1 30 30v7.2a30 30 0 0 1-30 30h-.9a30 30 0 0 1-30-30v-7.2a30 30 0 0 1 30-30Z" fill="',
                color,
                '"/>'
            )
        );
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
