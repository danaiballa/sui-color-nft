# !/bin/bash

# check dependencies are available.
for i in jq sui; do
  if ! command -V ${i} 2>/dev/null; then
    echo "${i} is not installed"
    exit 1
  fi
done

# default network is localnet
NETWORK=http://localhost:9000
FAUCET=https://localhost:9000/gas

# If otherwise specified chose testnet or devnet
if [ $# -ne 0 ]; then
  if [ "$1" = "testnet" ]; then
    NETWORK="https://fullnode.testnet.sui.io:443"
    FAUCET="https://faucet.testnet.sui.io/gas"
  fi
  if [ "$1" = "devnet" ]; then
    NETWORK="https://fullnode.devnet.sui.io:443"
    FAUCET="https://faucet.devnet.sui.io/gas"
  fi
  if [ "$1" = "mainnet" ]; then
    NETWORK="https://fullnode.mainnet.sui.io:443"
  fi
fi

publish_res=$(sui client publish --gas-budget 200000000 --skip-dependency-verification --json ../contracts/get_labs)

echo "${publish_res}" >.publish.res.json

if [[ "$publish_res" =~ "error" ]]; then
  # If yes, print the error message and exit the script
  echo "Error during move contract publishing.  Details : $publish_res"
  exit 1
fi
echo "Contract Deployment finished!"

echo "Setting up environmental variables..."

DIGEST=$(echo "${publish_res}" | jq -r '.digest')
PACKAGE_ID=$(echo "${publish_res}" | jq -r '.effects.created[] | select(.owner == "Immutable").reference.objectId')
newObjs=$(echo "$publish_res" | jq -r '.objectChanges[] | select(.type == "created")')
ADMIN_CAP=$(echo "$newObjs" | jq -r 'select (.objectType | contains("::get::AdminCap")).objectId')
PUBLISHER=$(echo "$newObjs" | jq -r 'select(.objectType | contains("::Publisher")).objectId' | head -n 1)
UPGRADE_CAP=$(echo "$newObjs" | jq -r 'select (.objectType | contains("::package::UpgradeCap")).objectId')
CONFIG=$(echo "$newObjs" | jq -r 'select (.objectType | contains("::get::Config")).objectId')
WHITELIST=$(echo "$newObjs" | jq -r 'select (.objectType | contains("::get::Whitelist")).objectId')
COLOR_CHANGER=$(echo "$newObjs" | jq -r 'select (.objectType | contains("::get::ColorChanger")).objectId')



ADMIN_PRIVATE_KEY=$(cat ~/.sui/sui_config/sui.keystore | jq -r '.[0]')

cat >.env <<-API_ENV
SUI_NETWORK=$NETWORK
DIGEST=$DIGEST
UPGRADE_CAP=$UPGRADE_CAP
PACKAGE_ID=$PACKAGE_ID
ADMIN_CAP=$ADMIN_CAP
PUBLISHER=${PUBLISHER}
CONFIG=${CONFIG}
WHITELIST=$WHITELIST
COLOR_CHANGER=$COLOR_CHANGER
ADMIN_PRIVATE_KEY=$ADMIN_PRIVATE_KEY
API_ENV