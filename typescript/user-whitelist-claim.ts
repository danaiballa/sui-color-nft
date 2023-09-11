import {
  SuiTransactionBlockResponse,
} from "@mysten/sui.js/client";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";

import { testnetClient, moduleFunctions } from "./setup";
import { getKeyPair } from "./helpers";
import { USER_PRIVATE_KEY, WHITELIST } from "./constants";

// TODO: giving the ke;air as input doesn't make much sense.
// in reality the wallet should sign with a built-in function.
async function userWhitelistClaim(
  userKeypair: Ed25519Keypair
): Promise<SuiTransactionBlockResponse> {
  let txb = new TransactionBlock();

  const get = txb.moveCall({
    target: moduleFunctions.userWhitelistClaim,
    arguments: [txb.object(WHITELIST)],
  });

  txb.transferObjects([get], txb.pure(userKeypair.getPublicKey().toSuiAddress()))

  txb.setGasBudget(100000000);

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
  const userKeypair = getKeyPair(USER_PRIVATE_KEY);
  const result = await userWhitelistClaim(userKeypair);
  console.log(result);
}

main();
