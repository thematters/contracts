## Design

### Introduction

The on-chain billboard system transforms platform attention into NFT billboards based on Harberger tax auctions. Empowering creators with a fair share of tax revenue through quadratic voting.

### Contracts

- [IBillboard](./IBillboard.md) / [Billboard](./Billboard.md): main entrance and interface.
- [IBillboardRegistry](./IBillboardRegistry.md) / [BillboardRegistry](./BillboardRegistry.md): storage contract for Billboard.
- [IDistribution](./IDistribution.md) / [Distribution](./Distribution.md): Tax distribution contract.

## Logic flow

### Billbaord auction

See [Billboard website](https://matters.town) for more details.

![auction](./auction.png)

### Tax distribution with QF (quadratic funding) algorithm

![distribution](./workflow.png)

## Deployment

Make file is at project root.

### Preprare environment

cp .env.local.example .env.local
cp .env.op-mainnet.example .env.op-mainnet

### Deploy to mainnet

Deploy Billboard

```
make deploy-billboard NETWORK=op-mainnet
```

Deploy Distribution

```
make deploy-billboard-billboard NETWORK=op-mainnet
```

## References

1. https://github.com/OpenZeppelin/merkle-tree
