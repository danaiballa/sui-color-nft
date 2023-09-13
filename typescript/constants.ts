import * as dotenv from "dotenv";
dotenv.config();

export const ADMIN_PRIVATE_KEY = process.env.ADMIN_PRIVATE_KEY!;
export const USER_PRIVATE_KEY = process.env.USER_PRIVATE_KEY!;

export const PACKAGE_ID = process.env.PACKAGE_ID!;
export const ADMIN_CAP = process.env.ADMIN_CAP!;
export const PUBLISHER = process.env.PUBLISHER!;
export const CONFIG = process.env.CONFIG!;
export const WHITELIST = process.env.WHITELIST!;
export const COLOR_CHANGER = process.env.COLOR_CHANGER!;
