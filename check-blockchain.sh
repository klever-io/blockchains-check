#!/bin/bash

hostname=$(hostname)
bsc_scan_token="api_key"

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
fi

# # ethereum test
# if [ ! -z $(echo $hostname|grep bsc) ]; then
#     actual_block=$(curl -k http://localhost:9137/api/v2|jq '.blockbook.bestHeight')
# fi


# printf %d $(curl -ks https://polygon-mainnet.g.alchemyapi.io/v2/demo \
#         -X POST \
#         -H "Content-Type: application/json" \
#         -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":0}'|jq '.result'|sed 's/\"//g')


echo $last_local_block $remote_block
calc=$(($last_local_block-$remote_block))
diff=$(echo ${calc#-})

 
if [ $diff -gt 0 ]; then
    curl -s -X POST --data-urlencode "payload={\"channel\": \"#blockchain-nodes-squad\", \"$network\": \"Matic\", \"text\": \"$network Node not synced ($hostname). The difference is $diff blocks\", \"icon_emoji\": \":thumbsdown:\"}" https://hooks.slack.com/services/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
fi
