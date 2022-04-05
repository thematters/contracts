[_The Space_](https://www.thespace.game/) is a pixel board organized by Harberger Tax and UBI, where each pixel is implemented as ERC721 token.

- An explainer of the idea can be found [here](https://medium.com/coinmonks/radical-markets-can-work-on-blockchain-our-web3-experiment-the-space-shows-how-1b5d49b91d27)
- Resources on Harberger Tax, also referred to as [Partial Common Ownership](https://www.radicalxchange.org/concepts/partial-common-ownership/)

## Contracts

- [TheSpace](./TheSpace.md): main entrance and interface. Inherit from [HarbergerMarket](./HarbergerMarket.md), and implements pixel-specific logical such as setting and reading colors.
- [HarbergerMarket](./HarbergerMarket.md): logic for trading ERC721 tokens under Harberger Tax and issuing UBI according to the number of token owned.
- [AccessRoles](./AccessRoles.md): special roles that can update settings or withdraw treasury on HarbergerMarket.
- [SpaceToken](./SpaceToken.md): standard ERC20 token that can be used as currency in HarbergerMarket.
