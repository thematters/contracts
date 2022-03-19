#!/usr/bin/env bash

source .env.${NETWORK}

if [ ${NETWORK} != "polygon-mumbai" ]
then
  echo "${NETWORK} is not supported"
  exit
fi

NOW=`date +%s`
MAX_GAS=1000000
TOKEN_ID=22
TITLE="hello, world! ${NOW}"
DESCRIPTION="Qui tempor sint minim amet. ${NOW}"
FORK_PRICE=10000
PUBLIC_SALE_PRICE=1000
CONTENT="Sint adipisicing esse adipisicing pariatur aliquip nulla voluptate ad consectetur cillum fugiat ${NOW}"
COMMISSION_BPS=150
DONATE_AMOUNT=123321

# claim, title, description, fork price, publish
CALLDATA_CLAIM=`cast calldata "claim(address,uint256)" ${DEPLOYER_ADDRESS} ${TOKEN_ID}`
CALLDATA_TITLE=`cast calldata "setTitle(uint256,string)" ${TOKEN_ID} "${TITLE}"`
CALLDATA_DESCRIPTION=`cast calldata "setDescription(uint256,string)" ${TOKEN_ID} "${DESCRIPTION}"`
CALLDATA_FORK_PRICE=`cast calldata "setForkPrice(uint256,uint256)" ${TOKEN_ID} ${FORK_PRICE}`
CALLDATA_PUBLISH=`cast calldata "publish(uint256,string)" ${TOKEN_ID} "${CONTENT}"`

cast send --gas ${MAX_GAS} --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} ${LOGBOOK_CONTRACT_ADDRESS} "multicall(bytes[])" "[${CALLDATA_CLAIM},${CALLDATA_TITLE},${CALLDATA_DESCRIPTION},${CALLDATA_FORK_PRICE},${CALLDATA_PUBLISH}]"

# public mint
CALLDATA_TURN_ON_PUBLIC_MINT=`cast calldata "turnOnPublicSale()"`
CALLDATA_PUBLIC_MINT_PRICE=`cast calldata "setPublicSalePrice(uint256)" ${PUBLIC_SALE_PRICE}`

cast send --gas ${MAX_GAS} --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} ${LOGBOOK_CONTRACT_ADDRESS} "multicall(bytes[])" "[${CALLDATA_TURN_ON_PUBLIC_MINT},${CALLDATA_PUBLIC_MINT_PRICE}]"

cast send --gas ${MAX_GAS} --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} ${LOGBOOK_CONTRACT_ADDRESS} "publicSaleMint()" --value ${PUBLIC_SALE_PRICE}

# donate
cast send --gas ${MAX_GAS} --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} ${LOGBOOK_CONTRACT_ADDRESS} "donate(uint256)" ${TOKEN_ID} --value ${DONATE_AMOUNT}

cast send --gas ${MAX_GAS} --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} ${LOGBOOK_CONTRACT_ADDRESS} "donateWithCommission(uint256,address,uint256)" ${TOKEN_ID} ${DEPLOYER_ADDRESS} ${COMMISSION_BPS} --value ${DONATE_AMOUNT}


# fork
cast send --gas ${MAX_GAS} --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} ${LOGBOOK_CONTRACT_ADDRESS} "fork(uint256,uint32)" ${TOKEN_ID} 1 --value ${FORK_PRICE}

cast send --gas ${MAX_GAS} --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} ${LOGBOOK_CONTRACT_ADDRESS} "forkWithCommission(uint256,uint32,address,uint256)" ${TOKEN_ID} 1 ${DEPLOYER_ADDRESS} ${COMMISSION_BPS} --value ${FORK_PRICE}
