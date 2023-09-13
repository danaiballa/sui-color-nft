import { SuiTransactionBlockResponse } from "@mysten/sui.js/client";
import { TransactionBlock } from "@mysten/sui.js/transactions";

import { getKeyPair } from "./helpers";
import { ADMIN_CAP, ADMIN_PRIVATE_KEY, CONFIG } from "./constants";
import { GetColor } from "./types";
import { moduleFunctions, testnetClient } from "./setup";

let adminKeypair = getKeyPair(ADMIN_PRIVATE_KEY);

export async function adminMintAndTransferGet(
  color: GetColor,
  recipient: string
): Promise<SuiTransactionBlockResponse> {
  let txb = new TransactionBlock();

  let get = txb.moveCall({
    target: moduleFunctions.adminMint,
    arguments: [txb.object(ADMIN_CAP), txb.pure(color), txb.object(CONFIG)],
  });

  txb.transferObjects([get], txb.pure(recipient));

  const result = await testnetClient.signAndExecuteTransactionBlock({
    signer: adminKeypair,
    transactionBlock: txb,
    options: {
      showEffects: true,
      showInput: false,
      showEvents: false,
      showObjectChanges: false,
      showBalanceChanges: false,
    },
  });

  return result;
}

async function main() {
  let mintResult = await adminMintAndTransferGet(
    "red",
    "0x1378f860144a2ab2e34622009e4a11b9228d245e444b0caf6289096206cbd496"
  );
  console.log(mintResult);
}

main();
