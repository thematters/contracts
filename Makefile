NETWORK ?= local # defaults to local node with ganache
include .env.$(NETWORK)

# Deps
update:; forge update

# Build & test
clean    :; forge clean
snapshot :; forge snapshot --gas-report
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
	@forge create ERC20 --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --constructor-args SpaceToken --constructor-args STK --legacy

deploy-the-space: clean
	@forge create TheSpace --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --constructor-args TheSpace --constructor-args SPACE --constructor-args ${THESPACE_CURRENCY_ADDRESS} --constructor-args 300 --constructor-args 1000000 --legacy

# Verifications
check-verification:
	@forge verify-check --chain-id ${CHAIN_ID} ${GUID} ${ETHERSCAN_API_KEY}

verify-logbook:
	@forge verify-contract --chain-id ${CHAIN_ID} --constructor-args ${LOGBOOK_ABI_ENCODE_CONSTRUCTOR_ARGS} --num-of-optimizations 200 --compiler-version v0.8.11+commit.d7f03943 ${LOGBOOK_CONTRACT_ADDRESS} src/Logbook/Logbook.sol:Logbook ${ETHERSCAN_API_KEY}

verify-the-space:
	@echo "TODO"
