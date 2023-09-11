import { SuiClient, SuiTransactionBlockResponse, getFullnodeUrl } from '@mysten/sui.js/client'
import { TransactionBlock } from '@mysten/sui.js/transactions';
import { getKeyPair } from './helpers';

import { ADMIN_CAP, ADMIN_PRIVATE_KEY, CONFIG, PACKAGE_ID } from './constants';
import { Color } from './types';

const client = new SuiClient({
	url: getFullnodeUrl("testnet"),
});

let adminKeypair = getKeyPair(ADMIN_PRIVATE_KEY);

export async function adminMintAndTransferGet(
  color: Color,
  recipient: string,
): Promise<SuiTransactionBlockResponse> {

  let txb = new TransactionBlock();

  let get = txb.moveCall(
    {
      target: `${PACKAGE_ID}::get::admin_mint`,
      arguments: [
        txb.object(ADMIN_CAP),
        txb.pure(color),
        txb.object(CONFIG),
      ]
    });

    txb.transferObjects([get], txb.pure(recipient));

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


async function main(){
  
  let mintResult = await adminMintAndTransferGet('red', '0x7e668cfe33143eb1e648494e05f0f6af8bb2595114563d318c27ead5043de80d');
  console.log(mintResult);

}

main()




