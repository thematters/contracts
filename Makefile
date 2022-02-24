NETWORK ?= local # defaults to local node with ganache
include .env.$(NETWORK)

# Deps
update:; forge update

# Build & test
clean    :; forge clean
snapshot :; forge snapshot
build: clean
	forge build
test:
	forge test -vvv
trace: clean
	forge test -vvvvv

# Deployments
## Logbook
deploy-logbook: clean
	@forge create Logbook --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --constructor-args Logbook --constructor-args LOGK --legacy

verify-logbook:
	@forge verify-contract --chain-id ${CHAIN_ID} --constructor-args 0x0000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000074c6f67626f6f6b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044c4f474b00000000000000000000000000000000000000000000000000000000 --compiler-version v0.8.4+commit.c7e474f2 ${CONTRACT_ADDRESS} src/Logbook/Logbook.sol:Logbook ${ETHERSCAN_API_KEY}

check-verification-status-logbook:
	@forge verify-check --chain-id ${CHAIN_ID} ${GUID} ${ETHERSCAN_API_KEY}

seeds-logbook:; @./bin/seed-logbook.sh

## The Space
deploy-the-space-currency: clean
	@forge create ERC20 --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --constructor-args SpaceToken --constructor-args STK --legacy

deploy-the-space: clean
	@forge create TheSpace --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --constructor-args TheSpace --constructor-args SPACE --constructor-args ${THESPACE_CURRENCY_ADDRESS} --constructor-args 300 --constructor-args 1000000 --legacy

verify-the-space:
	@echo "TODO"
