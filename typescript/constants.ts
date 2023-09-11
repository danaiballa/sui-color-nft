import * as dotenv from "dotenv";
dotenv.config();

// TODO: throw an error if the below are not defines

export const ADMIN_PRIVATE_KEY = process.env.ADMIN_PRIVATE_KEY!;

export const PACKAGE_ID = process.env.PACKAGE_ID;
export const ADMIN_CAP = process.env.ADMIN_CAP!;
export const CONFIG = process.env.CONFIG!;