import { SuiClient, getFullnodeUrl } from "@mysten/sui.js/client";
import { PACKAGE_ID } from "./constants";

export const moduleFunctions: {
  [key: string]: `${string}::${string}::${string}`;
} = {
  adminMint: `${PACKAGE_ID}::get::admin_mint`,
  adminWhitelistAdd: `${PACKAGE_ID}::get::admin_whitelist_add`,
  userWhitelistClaim: `${PACKAGE_ID}::get::user_whitelist_claim`,
};

export const testnetClient = new SuiClient({
  url: getFullnodeUrl("testnet"),
});
