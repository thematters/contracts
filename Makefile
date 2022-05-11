NETWORK ?= local # defaults to local node with ganache
include .env.$(NETWORK)

# Deps
update:; forge update

# Build & test
clean    :; forge clean
snapshot :; forge snapshot --gas-report --include-fuzz-tests
build: clean
	forge build
test:
	forge test --gas-report
trace: clean
	forge test -vvvvv --gas-report

# Deployments
## Logbook
deploy-logbook: clean
	@forge create Logbook --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --constructor-args Logbook --constructor-args LOGRS --legacy

seeds-logbook:; @./bin/seed-logbook.sh

## The Space
deploy-the-space-currency: clean
	@forge create SpaceToken --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --constructor-args ${THESPACE_TREASURY_ADDRESS} --constructor-args ${THESPACE_TREASURY_TOKENS} --constructor-args ${THESPACE_TEAM_ADDRESS} --constructor-args ${THESPACE_TEAM_TOKENS} --legacy

deploy-the-space: clean
	@forge create TheSpace --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --constructor-args ${THESPACE_CURRENCY_ADDRESS} --constructor-args ${THESPACE_ACL_MANAGER_ADDRESS} --constructor-args ${THESPACE_MARKET_ADMIN_ADDRESS} --constructor-args ${THESPACE_TREASURY_ADMIN_ADDRESS} --legacy

## snapper
deploy-snapper: clean
	@forge create Snapper --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --constructor-args ${SNAPPER_THESPACE_CREATION_BLOCKNUM} --constructor-args ${SNAPPER_THESPACE_INITIAL_SNAPSHOT_CID} --legacy

# Verifications
check-verification:
	@forge verify-check --chain-id ${CHAIN_ID} ${GUID} ${ETHERSCAN_API_KEY}

verify-logbook:
	@forge verify-contract --chain-id ${CHAIN_ID} --constructor-args ${LOGBOOK_ABI_ENCODE_CONSTRUCTOR_ARGS} --num-of-optimizations 200 --compiler-version v0.8.11+commit.d7f03943 ${LOGBOOK_CONTRACT_ADDRESS} src/Logbook/Logbook.sol:Logbook ${ETHERSCAN_API_KEY}

verify-the-space:
	@forge verify-contract --chain-id ${CHAIN_ID} --num-of-optimizations 200 --constructor-args ${THESPACE_ABI_ENCODE_CONSTRUCTOR_ARGS} --compiler-version v0.8.13+commit.abaa5c0e ${THESPACE_CONTRACT_ADDRESS} src/TheSpace/TheSpace.sol:TheSpace ${ETHERSCAN_API_KEY}

verify-snapper:
	@forge verify-contract --chain-id ${CHAIN_ID} --constructor-args `cast abi-encode "constructor(uint256,string)" ${SNAPPER_THESPACE_CREATION_BLOCKNUM} "${SNAPPER_THESPACE_INITIAL_SNAPSHOT_CID}" ` --num-of-optimizations 200 --compiler-version v0.8.11+commit.d7f03943 ${SNAPPER_CONTRACT_ADDRESS} src/Snapper/Snapper.sol:Snapper ${ETHERSCAN_API_KEY}
