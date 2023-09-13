import { SuiClient, getFullnodeUrl } from "@mysten/sui.js/client";
import { PACKAGE_ID } from "./constants";

export const moduleFunctions: {
  [key: string]: `${string}::${string}::${string}`;
} = {
  adminMint: `${PACKAGE_ID}::get::admin_mint`,
  adminWhitelistAdd: `${PACKAGE_ID}::get::admin_whitelist_add`,
  userWhitelistClaim: `${PACKAGE_ID}::get::user_whitelist_claim`,
  userPutForColorChange: `${PACKAGE_ID}::get::user_put_for_color_change`,
  adminColorChange: `${PACKAGE_ID}::get::admin_color_change`,
};

export const moduleTypes: {
  [key: string]: `${string}::${string}::${string}`;
} = {
  get: `${PACKAGE_ID}::get::Get`,
  transferPolicyCap: `0x2::transfer_policy::TransferPolicyCap<${PACKAGE_ID}::get::Get>`,
  transferPolicy: `0x2::transfer_policy::TransferPolicy<${PACKAGE_ID}::get::Get>`,
};

export const testnetClient = new SuiClient({
  url: getFullnodeUrl("testnet"),
});
