import { SuiTransactionBlockResponse } from "@mysten/sui.js/client";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import {
  createTransferPolicy,
  attachKioskLockRule,
  attachRoyaltyRule,
  testnetEnvironment,
  percentageToBasisPoints,
} from "@mysten/kiosk";

import { getKeyPair } from "./helpers";
import { ADMIN_PRIVATE_KEY, PUBLISHER } from "./constants";
import { moduleTypes, testnetClient } from "./setup";

const adminKeypair = getKeyPair(ADMIN_PRIVATE_KEY);

async function createPolicy() {
  const txb = new TransactionBlock();

  // create transfer policy
  let transferPolicyCap = createTransferPolicy(txb, moduleTypes.get, PUBLISHER);

  // transfer the Cap to the address.
  txb.transferObjects(
    [transferPolicyCap],
    txb.pure(adminKeypair.getPublicKey().toSuiAddress())
  );

  const result = await testnetClient.signAndExecuteTransactionBlock({
    signer: adminKeypair,
    transactionBlock: txb,
    options: {
      showEffects: true,
      showInput: false,
      showEvents: false,
      showObjectChanges: true,
      showBalanceChanges: false,
    },
  });

  return result;
}

// Attaches a royalty rule
// If `isStrongEnforcement` is set to `true`, also
// attaches a kiosk lock, making the objects trade-able only from/to a kiosk.
async function createTransferPolicyAndAttachRoyalties(
  policyID: string,
  policyCapID: string,
  royaltyPercentage: number,
  minAmount: number = 0,
  isStrongEnforcement: boolean = false
): Promise<SuiTransactionBlockResponse> {
  const txb = new TransactionBlock();

  if (isStrongEnforcement) {
    attachKioskLockRule(
      txb,
      moduleTypes.get,
      policyID,
      policyCapID,
      testnetEnvironment
    );
  }

  attachRoyaltyRule(
    txb,
    moduleTypes.get,
    policyID,
    policyCapID,
    percentageToBasisPoints(royaltyPercentage),
    minAmount,
    testnetEnvironment
  );

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
  let transferPolicyID: string | undefined;
  let transferPolicyCapID: string | undefined;
  const result = await createPolicy();
  console.log(result.objectChanges);
  const objectChanges = result.objectChanges;
  for (const objectChange of objectChanges!) {
    if (objectChange.type == "created") {
      if (objectChange.objectType == moduleTypes.transferPolicy) {
        // TODO: save this somewhere
        transferPolicyID = objectChange.objectId;
      } else if (objectChange.objectType == moduleTypes.transferPolicyCap) {
        // TODO: save this somewhere
        transferPolicyCapID = objectChange.objectId;
      }
    }
  }
  // royalties configuration.
  const percentage = 1; // 2.55%
  const minAmount = 100_000_000; // 0.1 SUI.

  if (transferPolicyCapID && transferPolicyID) {
    // call this with false to not make it strong
    const result = await createTransferPolicyAndAttachRoyalties(
      transferPolicyID,
      transferPolicyCapID,
      percentage,
      minAmount,
      true
    );
    console.log(result);
  } else {
    console.log("Error when creating transfer policy: objects not created");
  }
}

main();
