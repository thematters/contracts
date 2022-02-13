# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
update:; forge update

# Build & test
build    :; npm run build
test     :; npm run test
clean    :; npm run clean
snapshot :; forge snapshot

# Deployments
deploy :; @./scripts/deploy.sh

# polygon mainnet
deploy-polygon-mainnet:; echo deploying to polygon mainnet

# polygon mumbai
deploy-polygon-mumbai:; echo deploying to polygon mumbai

