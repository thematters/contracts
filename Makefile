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
	@forge verify-contract src/Logbook:Logbook ${CONTRACT_ADDRESS}

## The Space
deploy-the-space: clean
	@echo "TODO"

verify-the-space:
	@echo "TODO"
