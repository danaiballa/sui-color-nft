# sui-color-nft
An Demo of an NFT on sui.

[README is WIP]

## Project structure
- `contracts/get_labs` contains the smart contract and its tests.
- `scripts` contains an `.sh` script that can be used to publish the contract. The script saves automatically the addresses created in a `.env` file that can be used later to call the smart contracts.
- `typescript` contains typescript examples for calling the smart contract.

## Setup

### Move

### Typescript

## Smart contract design

### NFT struct

The `Get` struct stores a color. There are 7 colors available: "red", "orange", "yellow", "green", "blue", "indigo", "violet";
```
```

### Minting
There are three ways to mint a Get.
1. Admin-only mint. The function is protected/admin-only by requiring an `AdminCap` object that is only owned by the admin. An `AdminCap` object will be transferred to the publisher of the smart contract automatically via the `init` function, and there is also the possibility to create more `AdminCap`s.
2. User mint with a fee of 10 SUI while picking the color
3. User mint with a fee of 5 SUI with an arbitrary color.

In all three cases, the contract restricts the caller from minting a `Get` whose color is other than the 7 available colors.


### Fast-minting
All three ways of minting a `Get` are also available in fast mode, in which no shared objects are used and the transactions do not have to pass through consensus.

Note: the term Fast-minting comes from Fast Pay (insert link), a mechanism in which transactions don't need to pass through consensus but rather 

### `Get` Display

Example of a `Get`: https://suiexplorer.com/object/0xdf93e291a9f59ede70fce5d5a3e2319439cf467ce5f99710fcf2c31216bbf93e?network=testnet

### `Get` Editing
There are three ways to edit a `Get`, and all three require consent from the Admin.
1. Edit with `EditTicket`. The admin creates and sends an `EditTicket` object to the user, containing the new color of their `Get`.
  ```
  struct ...
  ```
  The user can use the `EditTicket` in the `edit_...` function to edit their `Get` color. The ticket is burned after the function is called, ensuring it cannot be re-used.
2. The user can put the get to a shared object, using the `...` function. Then the admin can then change its color using the `...` function, which also automatically returns the `Get` to its initial owner.
3. The admin can issue an off-chain time-expiring signature which the user can use to change the color of their `Get`.

### Whitelist
The admin can whitelist users by pre-minting a `Get` for each whitelisted user and adding it as a dynamic object field in the `Whitelist` shared object. The whitelisted user can them claim the `Get`.

### Tests
(add here a list of tests that were done)

## TS-SDK functions
In the `./typescript` file there are examples for
- Minting 
- Airdrop `Gets`
- Whitelist add and whitelist claim
- Construction of signature and editing with signature
- Editing with shared object approach


