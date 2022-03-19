// import * as ethers from "ethers";
const { ethers } = require("ethers");

const args = process.argv.slice(2);

// type Attribute = {
//   trait_type: string;
//   value: string;
// };

// type Metadata = { name: string; description: string; image: string; attributes: Attribute[] };

const abi = [
  "function metadata(tuple(string name, string description, tuple(string trait_type, string value)[] attributes) data, tuple(uint32 logCount, uint32 transferCount, uint256 tokenId) svgTexts)",
];
const iface = new ethers.utils.Interface(abi);

// parse metedata
const metadata = JSON.parse(Buffer.from(args[0].replace("data:application/json;base64,", ""), "base64").toString());

// extract SVG texts
const svg = Buffer.from(metadata.image.replace("data:image/svg+xml;base64,", ""), "base64").toString();
const logCount = parseInt(svg.replace(/.*Logs\/(\d+)\s.*/, "$1"), 10);
const tansfersCount = parseInt(svg.replace(/.*Transfers\/(\d+)\s.*/, "$1"), 10);
const tokenId = parseInt(svg.replace(/.*ID\/(\d+)\<\/tspan.*/, "$1"), 10);

// encode data
const encoded = iface.encodeFunctionData("metadata", [
  [metadata.name, metadata.description, metadata.attributes],
  [logCount, tansfersCount, tokenId],
]);

// output
process.stdout.write("0x" + encoded.slice(10));
