import { fromB64, BCS, getSuiMoveConfig } from "@mysten/bcs";
import { Ed25519Keypair, Ed25519PublicKey } from "@mysten/sui.js/keypairs/ed25519";
import { SUI_CLOCK_OBJECT_ID } from "@mysten/sui.js";
import { moduleTypes, testnetClient } from "./setup";

// import * as fs from 'fs';

/// helper to make keypair from private key that is in string format
export function getKeyPair(privateKey: string): Ed25519Keypair {
  let privateKeyArray = Array.from(fromB64(privateKey));
  privateKeyArray.shift();
  return Ed25519Keypair.fromSecretKey(Uint8Array.from(privateKeyArray));
}

export function formatAddress(suffix: string): string {
  const addressLength = 64;

  let numberOfLeadingZeroes = addressLength - suffix.length;
  let leadingZeroes = "";
  for (let i = 0; i < numberOfLeadingZeroes; i++) {
    leadingZeroes += "0";
  }

  return "0x" + leadingZeroes + suffix;
}

// TODO: function below that takes as input a string and writes it to .env
// export function writeToEnv(){

// }

export function constructMsgToSign(signatureData: {
  getID: string;
  newColor: string;
  expirationTimestamp: number;
}): Uint8Array {
  let msgToSign: Array<Uint8Array> = [];
  let bcs = new BCS(getSuiMoveConfig());

  // Remove the "0x" prefix and convert to Uint8Array
  const getIDBytes: Uint8Array = new Uint8Array(
    Buffer.from(signatureData.getID.slice(2), "hex")
  );
  const newColorBytes = bcs
    .ser(["string", BCS.STRING], signatureData.newColor)
    .toString("base64");
  const expirationTimestampBytes = bcs
    .ser(["u64", BCS.U64], signatureData.expirationTimestamp)
    .toString("base64");

  msgToSign.push(getIDBytes);
  msgToSign.push(Buffer.from(newColorBytes, "base64"));
  msgToSign.push(Buffer.from(expirationTimestampBytes, "base64"));

  // concatenate the individual Uint8 arrays to one array
  let msgToSignBytes = new Uint8Array();

  msgToSign.forEach((msg) => {
    msgToSignBytes = Uint8Array.from([...msgToSignBytes, ...msg]);
  });

  return msgToSignBytes;
}

export function publicKeyToBytes(publicKey: Ed25519PublicKey) {
  return Array.from(publicKey.toRawBytes())
}

export async function getCurrentTimestamp(): Promise<number> {
  const clockObjectResponse = await testnetClient.getObject({
    id: SUI_CLOCK_OBJECT_ID,
    options: { showContent: true },
  });
  let clockObjectContent: any = clockObjectResponse.data?.content;
  let timestamp_ms: string = clockObjectContent.fields.timestamp_ms;

  return Number(timestamp_ms);
}

export async function findGetsOfUser(userAddress: string): Promise<string[]> {
  // first get the user's Get objects
  let getGetObjectsResponse = await testnetClient.getOwnedObjects({
    owner: userAddress,
    filter: { StructType: moduleTypes.get },
  });


  let data = getGetObjectsResponse.data;

  let getIDs = data.map( (elem) => elem.data!.objectId)

  return getIDs;
}