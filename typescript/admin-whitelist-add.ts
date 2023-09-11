import {
  SuiTransactionBlockResponse,
} from "@mysten/sui.js/client";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { getKeyPair } from "./helpers";

import {
  ADMIN_CAP,
  ADMIN_PRIVATE_KEY,
  CONFIG,
  WHITELIST,
} from "./constants";
import { WhitelistData } from "./types";
import { testnetClient, moduleFunctions } from "./setup";

let adminKeypair = getKeyPair(ADMIN_PRIVATE_KEY);

async function adminWhitelistAdd(
  whitelistData: WhitelistData
): Promise<SuiTransactionBlockResponse> {
  let txb = new TransactionBlock();

  const [get] = txb.moveCall({
    target: moduleFunctions.adminMint,
    arguments: [
      txb.object(ADMIN_CAP),
      txb.pure(whitelistData.getColor),
      txb.object(CONFIG),
    ],
  });

  txb.moveCall({
    target: moduleFunctions.adminWhitelistAdd,
    arguments: [
      txb.object(ADMIN_CAP),
      txb.object(WHITELIST),
      get,
      txb.pure(whitelistData.whitelistedAddress),
    ],
  });

  const response = testnetClient.signAndExecuteTransactionBlock({
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

  return response;
}

async function main() {
  let response = await adminWhitelistAdd({
    whitelistedAddress:
      "0x1378f860144a2ab2e34622009e4a11b9228d245e444b0caf6289096206cbd496",
    getColor: "blue",
  });
  console.log(response);
}

main();