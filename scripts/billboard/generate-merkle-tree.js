const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const fs = require("fs");

// (1)
// [cid, address, amount]
const values = [
  [
    "Qmf5z5DKcwNWYUP9udvnSCTN2Se4A8kpZJY7JuUVFEqdGU",
    "0x0000000000000000000000000000000000000066",
    "1000000000000000000", // 1 USDT
  ],
  [
    "QmSAwncsWGXeqwrL5USBzQXvjqfH1nFfARLGM91sfd4NZe",
    "0x0000000000000000000000000000000000000067",
    "500000000000000000", // 0.5 USDT
  ],
  [
    "QmUQQSeWxcqoNLKroGtz137c7QBWpzbNr9RcqDtVzZxJ3x",
    "0x0000000000000000000000000000000000000068",
    "10000000000000000", // 0.01 USDT
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
