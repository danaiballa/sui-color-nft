export type Color =
  | "red"
  | "orange"
  | "yellow"
  | "green"
  | "blue"
  | "indigo"
  | "violet";

export type address = string;

export type AirdropData = {
  recipient: address;
  getColor: Color;
};

export type WhitelistData = {
  whitelistedAddress: address;
  getColor: Color;
};
