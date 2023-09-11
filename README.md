# sui-color-nft
An implementation of an NFT representing colors on sui.

An imaginary company, GetLabs, has an NFT named `Get`.

## Smart contract design

### NFT struct


### Minting
There are three ways to mint a Get.
1. Admin-only mint. The function is protected/admin-only by requiring `AdminCap`. An `AdminCap` object will be transferred to the publisher of the smart contract automatically via the `init` function.
  ```
  /// Admin-only function, mints and returns a Get object
  public fun admin_mint(_: &AdminCap, color: String, ctx: &mut TxContext): Get {
   ```
1. User mint with a fee of 10 SUI while picking the color
2. User mint with a fee of 5 SUI with random color (write a note on randomness)


### Fast-minting
(Fast-minting as in Fast Pay, no consensus :)

### `Get` Display

(add an example on explorer for various colors)

### `Get` Editing
There are three ways to edit a `Get`, and all three require consent from the Admin.

### Whitelist

### Royalties
WIP

### Tests
(add here a list of tests that were done)

## TS-SDK functions


