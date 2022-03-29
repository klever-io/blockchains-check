#!/bin/bash
#set -x

hostname=$(hostname)
diff_acceptable=10
slack_token="------------------------"
bsc_scan_token="------------------------"
eth_scan_token="------------------------"

# Matic test
if [ ! -z $(echo $hostname|grep matic) ]; then
    echo "Isso é Matic"
    last_local_block=$(printf %d $(curl -s -X POST  -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":83}' localhost:8545|jq '.result'|sed 's/\"//g'))
    remote_block=$(printf %d $(curl -ks https://polygon-mainnet.g.alchemyapi.io/v2/demo \
      -X POST \
      -H "Content-Type: application/json" \
      -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":0}'|jq '.result'|sed 's/\"//g'))
    network='Matic'
fi

# bsc test
if [ ! -z $(echo $hostname|grep bsc) ]; then
    last_local_block=$(curl -k http://localhost:9137/api/v2|jq '.blockbook.bestHeight')
    remote_block=$(curl "https://api.bscscan.com/api?module=block&action=getblocknobytime&timestamp=$(date +%s)&closest=before&apikey=$bsc_scan_token"|jq '.result'|sed 's/\"//g')
    network='BSC'
fi

# ethereum test
if [ ! -z $(echo $hostname|grep eth) ]; then
    last_local_block=$(curl -k http://localhost:9136/api/v2|jq '.blockbook.bestHeight')
    remote_block=$(curl -ks "https://api.etherscan.io/api?module=block&action=getblocknobytime&timestamp=$(date +%s)&closest=before&apikey=$eth_scan_token"|jq '.result'|sed 's/\"//g')
    network='ETH'
fi

# kusama test
if [ ! -z $(echo $hostname|grep kusama) ]; then
    last_local_block=$(curl -ks --request POST --url http://localhost:8082/v1/graphql --header 'Content-Type: application/json' --header 'x-hasura-admin-secret: klever' --data '{"query":"query GetBlocks {\n  block(limit: 1, order_by: {block_number: desc})  {\n    block_number\n    block_hash\n    total_extrinsics\n    finalized\n    timestamp\n  }\n}","operationName":"GetBlocks"}'|jq '.data.block[0].block_number')
    remote_block=$(curl -sS -X POST -H "x-api-key: YOUR_KEY" https://kusama.api.subscan.io/api/scan/metadata|jq '.data.blockNum'|sed 's/\"//g')
    network='KUSAMA'
fi

# btc test
if [ ! -z $(echo $hostname|grep btc) ]; then
    last_local_block=$(curl -ks http://localhost:9130/api/v3|jq '.blockbook.bestHeight')
    remote_block=$(curl -ks https://chain.api.btc.com/v3/block/latest|jq '.data.height')
    network='BTC'
fi

# echo $last_local_block $remote_block
calc=$(($last_local_block-$remote_block))
diff=$(echo ${calc#-})

 
if [ $diff -gt $diff_acceptable ]; then
    curl -s -X POST --data-urlencode "payload={\"channel\": \"#blockchain-nodes-squad\", \"$network\": \"$network\", \"text\": \"$network Node not synced ($hostname). The difference is $diff blocks\", \"icon_emoji\": \":thumbsdown:\"}" https://hooks.slack.com/services/$slack_token
fi