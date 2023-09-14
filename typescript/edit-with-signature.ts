import { SuiTransactionBlockResponse } from "@mysten/sui.js/client";
import { TransactionBlock } from "@mysten/sui.js/transactions";

import {
  getKeyPair,
  constructMsgToSign,
  getCurrentTimestamp,
  findGetsOfUser,
  publicKeyToBytes,
} from "./helpers";
import {
  ADMIN_CAP,
  ADMIN_PRIVATE_KEY,
  CONFIG,
  USER_PRIVATE_KEY,
} from "./constants";
import { GetColor } from "./types";
import { moduleFunctions, testnetClient } from "./setup";
import { Ed25519PublicKey, SUI_CLOCK_OBJECT_ID } from "@mysten/sui.js";

const userKeyPair = getKeyPair(USER_PRIVATE_KEY);
const adminKeypair = getKeyPair(ADMIN_PRIVATE_KEY);

async function editGetWithSignature(
  signatureData: {
    getID: string;
    newColor: string;
    expirationTimestamp: number;
  },
  signedMessage: number[]
): Promise<SuiTransactionBlockResponse> {
  let txb = new TransactionBlock();

  txb.moveCall({
    target: moduleFunctions.updateWithSignature,
    arguments: [
      txb.object(signatureData.getID),
      txb.pure(signatureData.newColor),
      txb.pure(signatureData.expirationTimestamp),
      txb.pure(signedMessage),
      txb.object(CONFIG),
      // TODO: this is deprecated, how to find the new variable?
      txb.object(SUI_CLOCK_OBJECT_ID),
    ],
  });

  const result = await testnetClient.signAndExecuteTransactionBlock({
    signer: userKeyPair,
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

async function adminEditPublicKey(
  newPublicKey: Ed25519PublicKey
): Promise<SuiTransactionBlockResponse> {
  const txb = new TransactionBlock();

  const newPublicKeyBytes = publicKeyToBytes(newPublicKey);

  txb.moveCall({
    target: moduleFunctions.adminEditPublicKey,
    arguments: [
      txb.object(ADMIN_CAP),
      txb.pure(newPublicKeyBytes),
      txb.object(CONFIG),
    ],
  });

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

  // admin sets their public key in Config object
  console.log("--- Admin sets public key ---");
  const setPKResult = await adminEditPublicKey(adminKeypair.getPublicKey());
  console.log(setPKResult);

  // find a get of the user
  const getIDs = await findGetsOfUser(
    userKeyPair.getPublicKey().toSuiAddress()
  );

  if (getIDs.length == 0) {
    console.log("User has no Gets");
    return;
  }

  // admin signs a message for user
  // take the first Get of user, in reality we would pick one with some criteria
  const getID = getIDs[0];
  const newColor: GetColor = "indigo";
  const currentTimestamp = await getCurrentTimestamp();
  const expirationTimestamp = currentTimestamp + 600000; // 600000 is 10 minutes in miliseconds
  const msgToSignBytes = constructMsgToSign({
    getID,
    newColor,
    expirationTimestamp,
  });
  const signedMessage = Array.from(adminKeypair.signData(msgToSignBytes));
  console.log("--- Signed Message ---");
  console.log(signedMessage);

  // user uses this message to update their Get
  const result = await editGetWithSignature(
    { getID, newColor, expirationTimestamp },
    signedMessage
  );

  console.log("--- Update with signature result ---");
  console.log(result);
}

main();
