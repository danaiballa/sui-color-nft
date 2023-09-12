import { SuiTransactionBlockResponse } from "@mysten/sui.js/client";
import { TransactionBlock } from "@mysten/sui.js/transactions";

import { getKeyPair } from "./helpers";
import {
  ADMIN_CAP,
  ADMIN_PRIVATE_KEY,
  COLOR_CHANGER,
  CONFIG,
} from "./constants";
import { moduleFunctions, moduleTypes, testnetClient } from "./setup";
import { GetColor } from "./types";

const adminKeypair = getKeyPair(ADMIN_PRIVATE_KEY);

async function adminColorChange(
  getID: string,
  newGetColor: GetColor
): Promise<SuiTransactionBlockResponse> {
  let txb = new TransactionBlock();

  txb.moveCall({
    target: moduleFunctions.adminColorChange,
    arguments: [
      txb.object(ADMIN_CAP),
      txb.object(COLOR_CHANGER),
      txb.object(CONFIG),
      txb.pure(getID),
      txb.pure(newGetColor),
    ],
  });

  txb.setGasBudget(10000000);

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

// In this function we get all Dfs of ColorChanger and we find the get IDs
// that have been put for color change.
// In reality we would have an event listener to listen to `GetPutForColorChange` events
async function findGetIDsForColorChange(): Promise<string[]> {
  const dynamicFieldsResponse = await testnetClient.getDynamicFields({
    parentId: COLOR_CHANGER,
  });

  let getIDs = dynamicFieldsResponse.data.map(
    (elem) => elem.name.value as string
  );

  return getIDs;
}

async function main() {
  const getIDs = await findGetIDsForColorChange();
  if (getIDs.length == 0){
    console.log("No Gets to update");
    return
  }
  // we change all colors to 'indigo'
  for (const getID of getIDs) {
    const response = await adminColorChange(getID, "indigo");
    if (response.effects?.status.status == "success") {
      console.log(`------- Color Update -------`);
      console.log(`Color of Get with id ${getID} updated to 'indigo'`);
    } else {
      console.log(`Error: ${response.effects?.status.error}`);
    }
  }
}

main();
