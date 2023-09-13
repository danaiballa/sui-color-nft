export type GetColor =
  | "red"
  | "orange"
  | "yellow"
  | "green"
  | "blue"
  | "indigo"
  | "violet";

export type AirdropData = {
  recipient: string;
  getColor: GetColor;
};

export type WhitelistData = {
  whitelistedAddress: string;
  getColor: GetColor;
};