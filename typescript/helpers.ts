import { fromB64 } from "@mysten/bcs";
import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";

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

  return '0x' + leadingZeroes + suffix;
}
