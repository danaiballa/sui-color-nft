import { ADMIN_PRIVATE_KEY } from "./constants";
import { constructMsgToSign, getKeyPair, publicKeyToBytes } from "./helpers";
import { GetColor } from "./types";

function main() {
  const adminKeypair = getKeyPair(ADMIN_PRIVATE_KEY);
  // we find this ID by debug::print the Get ID in test
  const getID = "0xdba72804cc9504a82bbaa13ed4a83a0e2c6219d7e45125cf57fd10cbab957a97";
  const newColor: GetColor = "indigo";
  const expirationTimestamp = 60000; // 10 minutes, clock will start from 0 in tests

  console.log("--- Admin Public Key Bytes---");
  const adminPublicKeyBytes = publicKeyToBytes(adminKeypair.getPublicKey());
  console.log(adminPublicKeyBytes);

  const msgToSignBytes = constructMsgToSign({
    getID,
    newColor,
    expirationTimestamp,
  });
  const signedMessage = Array.from(adminKeypair.signData(msgToSignBytes));
  console.log("--- Signed Message ---");
  console.log(signedMessage);
}

main();
