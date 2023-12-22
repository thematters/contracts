## Design

### Introduction

The on-chain billboard system transforms platform attention into NFT billboards based on Harberger tax auctions. Empowering creators with a fair share of tax revenue through quadratic voting.

### Contracts

- [IBillboard](./IBillboard.md)/[Billboard](./Billboard.md): main entrance and interface.
- [IBillboardRegistry](./IBillboardRegistry.md)/[BillboardRegistry](./BillboardRegistry.md): storage contract for Billboard.
- [IDistribution](./IDistribution.md)/[Distribution](./Distribution.md): Tax distribution contract.

## Logic flow

### Billbaord auction

See [Billboard website](https://matters.town) for more details.

### Tax distribution with QF (quadratic funding) algorithm

![distribution](./distribution.svg)

1. The cron job calls QF lambda function with a given time range to calculate the score of each CID-Address pair, and generate merkle tree [1] for distribution.
2. The cron job calls Billboard contract to clear auction and receive tax.
3. The cron job calls Distribution contract with the merkle tree root to distribute tax.

## Deployment

Make file is at project root.

### Preprare environment

cp .env.local.example .env.local
cp .env.polygon-mainnet.example .env.polygon-mainnet
cp .env.polygon-mumbai.example .env.polygon-mumbai

### Deploy to mainnet

Deploy Billboard

```
make deploy-billboard NETWORK=polygon-mainnet
```

Deploy Distribution

```
make deploy-billboard-billboard NETWORK=polygon-mainnet
```

## References

1. https://github.com/OpenZeppelin/merkle-tree
