// Before running this make sure user has Gets
// You can use mint.ts to mint Get for a user
import { SuiTransactionBlockResponse } from "@mysten/sui.js/client";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";

import { getKeyPair, findGetsOfUser} from "./helpers";
import { COLOR_CHANGER, USER_PRIVATE_KEY } from "./constants";
import { moduleFunctions, moduleTypes, testnetClient } from "./setup";

async function userPutForColorChange(
  getID: string,
  userKeypair: Ed25519Keypair
): Promise<SuiTransactionBlockResponse> {
  let txb = new TransactionBlock();

  txb.moveCall({
    target: moduleFunctions.userPutForColorChange,
    arguments: [txb.object(getID), txb.object(COLOR_CHANGER)],
  });

  const result = await testnetClient.signAndExecuteTransactionBlock({
    signer: userKeypair,
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
  let userKeypair = getKeyPair(USER_PRIVATE_KEY);
  let userAddress = userKeypair.getPublicKey().toSuiAddress();

  // first get the user's Get objects
  let getIDs = await findGetsOfUser(userAddress);

  if (getIDs.length == 0) {
    console.log("User has no Gets!");
  } else {
    // pick the first one and put it for color change
    // in reality we could have a UI that allows user to pick the object they want
    let getID = getIDs[0];

    let result = await userPutForColorChange(getID, userKeypair);
    console.log(result);
  }
}

main();
