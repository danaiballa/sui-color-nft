export type GetColor =
  | "red"
  | "orange"
  | "yellow"
  | "green"
  | "blue"
  | "indigo"
  | "violet";

// TODO: restrict this type to have proper length and be hex
export type Address = `0x${string}`;

export type AirdropData = {
  recipient: Address;
  getColor: GetColor;
};

export type WhitelistData = {
  whitelistedAddress: Address;
  getColor: GetColor;
};