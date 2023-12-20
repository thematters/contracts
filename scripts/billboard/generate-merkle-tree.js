import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs";

// (1)
// [cid, address, amount]
const values = [
  [
    "Qmf5z5DKcwNWYUP9udvnSCTN2Se4A8kpZJY7JuUVFEqdGU",
    "0x0000000000000000000000000000000000000102",
    "1000000000000000000", // 1 ethers
  ],
  [
    "QmSAwncsWGXeqwrL5USBzQXvjqfH1nFfARLGM91sfd4NZe",
    "0x0000000000000000000000000000000000000102",
    "500000000000000000", // 0.5 ethers
  ],
  [
    "QmUQQSeWxcqoNLKroGtz137c7QBWpzbNr9RcqDtVzZxJ3x",
    "0x0000000000000000000000000000000000000103",
    "10000000000000000", // 0.01 ethers
  ],
];

// (2)
const tree = StandardMerkleTree.of(values, ["string", "address", "uint256"]);

// (3)
console.log("Merkle Root:", tree.root);

// (4)
fs.writeFileSync("out/tree.json", JSON.stringify(tree.dump()));

// get proofs
const treeLoaded = StandardMerkleTree.load(JSON.parse(fs.readFileSync("out/tree.json", "utf8")));

for (const [i, v] of treeLoaded.entries()) {
  const proof = treeLoaded.getProof(i);
  console.log("Value:", v);
  console.log("Proof:", proof);
}
