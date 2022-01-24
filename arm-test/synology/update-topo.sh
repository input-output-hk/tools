#!/bin/sh
BASE="https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1"
for net in mainnet testnet; do
    for file in config byron-genesis shelley-genesis alonzo-genesis topology db-sync-config; do
        curl -LO "${BASE}/${net}-${file}.json"
    done
done
curl -LO "${BASE}/rest-config.json"
curl -LO "https://raw.githubusercontent.com/input-output-hk/cardano-node/master/cardano-submit-api/config/tx-submit-mainnet-config.yaml"
