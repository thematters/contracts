NETWORK ?= local # defaults to local node with ganache
include .env.$(NETWORK)

# Deps
update:; forge update

# Build & test
build    :; npm run build
test     :; npm run test
clean    :; npm run clean
snapshot :; forge snapshot

# Deployments

## Logbook
deploy-logbook: clean
	@forge create Logbook --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --constructor-args Logbook --constructor-args LOGK --legacy

## The Space
deploy-the-space: clean
	@echo "TODO"
