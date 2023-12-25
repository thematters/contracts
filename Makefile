NETWORK ?= local # defaults to local node
include .env.$(NETWORK)

# Deps
update:; forge update

# Build & test
clean    :; forge clean
snapshot :; forge snapshot
gas-report :; forge test --gas-report
coverage :; forge coverage --report=summary
build: clean
	forge build
test:
	forge test -vvv
trace: clean
	forge test -vvvvv

# Static Analyzers
analyze-logbook   :; slither src/Logbook/Logbook.sol
analyze-the-space :; slither src/TheSpace/TheSpace.sol
analyze-curation  :; slither src/Curation/Curation.sol
analyze-billboard :; slither src/Billboard/Billboard.sol
analyze-billboard-distribution :; slither src/Billboard/Distribution.sol

# Deployments
## Logbook
deploy-logbook: clean
	@forge create Logbook --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --constructor-args Logbook --constructor-args LOGRS --legacy --verify --etherscan-api-key ${ETHERSCAN_API_KEY}

seeds-logbook:; @./bin/seed-logbook.sh

## The Space
deploy-the-space-currency: clean
	@forge create SpaceToken --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --constructor-args ${THESPACE_TREASURY_ADDRESS} --constructor-args ${THESPACE_TREASURY_TOKENS} --constructor-args ${THESPACE_TEAM_ADDRESS} --constructor-args ${THESPACE_TEAM_TOKENS} --constructor-args ${THESPACE_INCENTIVES_ADDRESS} --constructor-args ${THESPACE_INCENTIVES_TOKENS} --constructor-args ${THESPACE_LP_ADDRESS} --constructor-args ${THESPACE_LP_TOKENS} --legacy --verify --etherscan-api-key ${ETHERSCAN_API_KEY}

deploy-the-space: clean
	@forge create TheSpace --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --constructor-args ${THESPACE_CURRENCY_ADDRESS} --constructor-args ${THESPACE_REGISTRY_ADDRESS} --constructor-args ${THESPACE_TOKEN_IMAGE_URI} --constructor-args ${THESPACE_ACL_MANAGER_ADDRESS} --constructor-args ${THESPACE_MARKET_ADMIN_ADDRESS} --constructor-args ${THESPACE_TREASURY_ADMIN_ADDRESS} --legacy --verify --etherscan-api-key ${ETHERSCAN_API_KEY}

## The Space: snapper
deploy-snapper: clean
	@forge create Snapper --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --legacy --verify --etherscan-api-key ${ETHERSCAN_API_KEY}

## Curation
deploy-curation: clean
	@forge create Curation --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --legacy --verify --etherscan-api-key ${ETHERSCAN_API_KEY}

## Billboard
deploy-billboard: clean
	@forge create Billboard --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --constructor-args ${BILLBOARD_ERC20_TOKEN} ${BILLBOARD_REGISTRY_ADDRESS} 7 ${BILLBOARD_LEASE_TERM} "Billboard" "BLBD" --legacy --verify --etherscan-api-key ${ETHERSCAN_API_KEY}

deploy-billboard-distribution: clean
	@forge create Distribution --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --constructor-args ${BILLBOARD_ERC20_TOKEN} ${BILLBOARD_DISTRIBUTION_ADMIN_ADDRESS} --legacy --verify --etherscan-api-key ${ETHERSCAN_API_KEY}
