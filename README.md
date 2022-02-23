# Contracts for Matters Protocol

## Development

Install [Forge](https://github.com/gakonst/foundry)

Environment

```bash
cp .env.local.example .env.local
```

Build

```bash
make build
```

Testing

```bash
make test
```

## Deployment

### Deploy on Local Node:

```bash
# Run local node
npm run ganache

# Preprare environment
cp .env.local.example .env.local
cp .env.polygon-mainnet.example .env.polygon-mainnet
cp .env.polygon-mumbai.example .env.polygon-mumbai

# Deploy Logbook contract (defaults to local node)
make deploy-logbook

# Deploy currency first, then add the contract address to THESPACE_CURRENCY_ADDRESS env variable
make deploy-the-space-currency
# Deploy the space contract
make deploy-the-space
```

### Deploy on testnet or mainnet:

```bash
# Deploy The Space contract
make deploy-the-space

# Deploy to Poygon Mainnet
make deploy-the-space NETWORK=polygon-mainnet

# Deploy to Polygon Mumbai
make deploy-the-space NETWORK=polygon-mumbai
```

## Verify Contract

[Automatically](https://onbjerg.github.io/foundry-book/forge/deploying.html#verifying)

```bash
# Verify on Poygon Mainnet
make verify-the-space NETWORK=polygon-mainnet

# Verify on Polygon Mumbai
make verify-the-space NETWORK=polygon-mumbai
```

Manually

```bash
# 1. Concat all file into one
forge flatten src/Logbook/Logbook.sol

# 2. On (Polygonscan)[https://mumbai.polygonscan.com/verifycontract], Select "Solidity (Single File)" and upload
```
