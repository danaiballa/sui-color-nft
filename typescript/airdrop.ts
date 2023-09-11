import { SuiClient, SuiTransactionBlockResponse, getFullnodeUrl } from '@mysten/sui.js/client'
import { TransactionBlock } from '@mysten/sui.js/transactions';
import { getKeyPair, formatAddress } from './helpers';

import { ADMIN_CAP, ADMIN_PRIVATE_KEY, CONFIG, PACKAGE_ID } from './constants';
import { airdropData } from "./types";

const adminKeypair = getKeyPair(ADMIN_PRIVATE_KEY);

const client = new SuiClient({
	url: getFullnodeUrl("testnet"),
});

async function airdrop(
  data: airdropData[]
): Promise<SuiTransactionBlockResponse> {

  let txb = new TransactionBlock();

  for (const airdropData of data){

    let get = txb.moveCall({
      target: `${PACKAGE_ID}::get::admin_mint`,
      arguments: [
        txb.object(ADMIN_CAP),
        txb.pure(airdropData.getColor),
        txb.object(CONFIG)
      ]
    });
    txb.transferObjects([get], txb.pure(airdropData.recipient))
  }

  txb.setGasBudget(10000000000)

  const result = await client.signAndExecuteTransactionBlock({
    signer: adminKeypair,
    transactionBlock: txb,
    options: {
      showEffects: true,
      showInput: false,
      showEvents: false,
      showObjectChanges: false,
      showBalanceChanges: false,
    }
  });

  return result
}

// everyone will get indigo in the airdrop
// Note: for 1000 addresses we need 2 transactions
// since a txb supports up to 1024 commands and we need 2 commands to airdrop to one address
// (one for minting and one for transferring)
// However, the public fullnode does not support 1024 transactions
// So we airdrop for 50 and flow for more is similar
async function main(){

  let data: airdropData[] = [];

  for (let i = 0; i<50; i++){
    data.push(
      {
        recipient: formatAddress(String(i)),
        getColor: 'indigo'
      }
    )
  }

  const result = await airdrop(data);
  console.log(result);
}

main();