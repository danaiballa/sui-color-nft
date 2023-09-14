module get_labs::get{

  use std::string::{Self, String};
  use std::vector;

  use sui::address;
  use sui::bcs;
  use sui::coin::{Self, Coin};
  use sui::clock::{Self, Clock};
  use sui::display;
  use sui::dynamic_field as df;
  use sui::dynamic_object_field as dof;
  use sui::ed25519;
  use sui::event;
  use sui::package;
  use sui::object::{Self, ID, UID};
  use sui::sui::SUI;
  use sui::transfer;
  use sui::tx_context::{Self, TxContext};

  const PROFITS_ADDRESS: address = @0x10;
  const PRICE_MINT_SELECTED: u64 = 10_000_000;
  const PRICE_MINT_ARBITRARY: u64 = 5_000_000;

  const EInvalidColor: u64 = 0;
  const EInvalidCoinValue: u64 = 1;
  const EInvalidId: u64 = 2;
  const EUserAlreadyWhitelisted: u64 = 3;
  const EUserNotWhitelisted: u64 = 4;
  const EGetIsNotPutForColorChange: u64 = 5;
  const EInvalidSignature: u64 = 6;
  const ESignatureExpired: u64 = 7;

  // OTW for display
  struct GET has drop {}

  // nft struct
  struct Get has key, store {
    id: UID,
    color: String,
  }

  // Admin cap to mint Gets
  struct AdminCap has key, store {
    id: UID,
  }

  // will be a shared object
  struct Config has key, store {
    id: UID,
    admin_public_key: vector<u8>,
    profits_address: address,
    available_colors: vector<String>,
    price_mint_selected: u64,
    price_mint_arbitrary: u64,
  }

  // will store Gets pending for claim from whitelisted addresses
  struct Whitelist has key, store {
    id: UID,
  }

  // --- Objects for color updates ---

  // edit ticket object
  struct EditTicket has key, store {
    id: UID,
    get_id: ID,
    new_color: String,
  }

  // shared object that will store Get objects pending for color upgrade
  struct ColorChanger has key, store {
    id: UID,
  }

  // TODO: WrappedGet for ColorChanger 
  // (so that a user can add more than one Color for upgrade at the same time)
  struct WrappedGet has store {
    owner: address,
    get: Get,
  }

  // --- Events ---

  // Event emitted when a user puts a Get for upgrade in the ColorChanger object
  struct GetPutForColorChange has copy, drop {
    owner: address,
    get_id: ID,
  }

  fun init(otw: GET, ctx: &mut TxContext){

    // claim publisher
    let publisher = package::claim(otw, ctx);

    // create display
    let keys = vector[string::utf8(b"image_url")];
    let values = vector[string::utf8(b"https://placehold.co/600x600/{color}/{color}")];
    let display = display::new_with_fields<Get>(&publisher, keys, values, ctx);

    // Commit first version of `Display` to apply changes.
    display::update_version(&mut display);

    // initialize Config struct
    let available_colors = get_hardcoded_available_colors();

    let config = Config {
      id: object::new(ctx),
      // If we know the publc key, we could initialize it here
      admin_public_key: vector::empty<u8>(),
      profits_address: PROFITS_ADDRESS,
      available_colors,
      price_mint_selected: PRICE_MINT_SELECTED,
      price_mint_arbitrary: PRICE_MINT_ARBITRARY,
    };

    let admin_cap = AdminCap {id: object::new(ctx)};

    let whitelist = Whitelist { id: object::new(ctx) };

    let color_changer = ColorChanger { id: object::new(ctx) };

    transfer::share_object(config);
    transfer::share_object(whitelist);
    transfer::share_object(color_changer);

    let sender = tx_context::sender(ctx);

    transfer::public_transfer(display, sender);
    transfer::public_transfer(publisher, sender);
    transfer::public_transfer(admin_cap, sender);
  }

  // === Admin-only functions ===

  /// Admin-only function, mints and returns a Get object
  public fun admin_mint(_: &AdminCap, color: String, config: &Config, ctx: &mut TxContext): Get {

    mint(color, config.available_colors, ctx)
  }

  /// No-consensus admin mint
  public fun admin_fast_mint(_: &AdminCap, color: String, ctx: &mut TxContext): Get {

    let available_colors = get_hardcoded_available_colors();

    mint(color, available_colors, ctx)
  }

  public fun admin_create_edit_ticket(_: &AdminCap, get_id: ID, new_color: String, config: &Config, ctx: &mut TxContext): EditTicket {

    create_edit_ticket(get_id, new_color, config.available_colors, ctx)

  }

  public fun admin_fast_create_edit_ticket(_: &AdminCap, get_id: ID, new_color: String, ctx: &mut TxContext): EditTicket {

    let available_colors = get_hardcoded_available_colors();

    create_edit_ticket(get_id, new_color, available_colors, ctx)
  }

  public fun admin_edit_available_colors(
    _: &AdminCap,
    new_available_colors: vector<String>,
    config: &mut Config,
  ) {
    config.available_colors = new_available_colors;
  }

  public fun admin_edit_price_mint_selected(
    _: &AdminCap,
    new_price_mint_selected: u64,
    config: &mut Config,
  ) {
    config.price_mint_selected = new_price_mint_selected;
  }

  public fun admin_edit_price_mint_arbitrary(
    _: &AdminCap,
    new_price_mint_arbitrary: u64,
    config: &mut Config,
  ) {
    config.price_mint_arbitrary = new_price_mint_arbitrary;
  }

  public fun admin_edit_profits_address(
    _: &AdminCap,
    new_profits_address: address,
    config: &mut Config,
  ) {
    config.profits_address = new_profits_address;
  }

  public fun admin_edit_public_key(
    _: &AdminCap,
    new_public_key: vector<u8>,
    config: &mut Config,
  ) {
    config.admin_public_key = new_public_key;
  }

  public fun admin_create_extra_admin_cap(
    _: &AdminCap,
    ctx: &mut TxContext,
  ): AdminCap {
    AdminCap { id: object::new(ctx) }
  }

  public fun admin_whitelist_add(_: &AdminCap, whitelist: &mut Whitelist, get: Get, user_address: address){
    assert!(!dof::exists_<address>(&whitelist.id, user_address), EUserAlreadyWhitelisted);
    dof::add<address, Get>(&mut whitelist.id, user_address, get);
  }

  public fun admin_color_change(_: &AdminCap, color_changer: &mut ColorChanger, config: &Config, get_id: ID, new_color: String) {

    assert!(df::exists_<ID>(&color_changer.id, get_id), EGetIsNotPutForColorChange);

    let wrapped_get = df::remove<ID, WrappedGet>(&mut color_changer.id, get_id);

    let WrappedGet { owner, get } = wrapped_get;
    
    assert!(belongs_in_available_colors(config.available_colors, new_color), EInvalidColor);
    get.color = new_color;

    transfer::transfer(get, owner);
  }

  // === User functions ===

  public fun user_mint_selected(coin: Coin<SUI>, color: String, config: &Config, ctx: &mut TxContext): Get {

    mint_selected(coin, color, config.available_colors, config.price_mint_selected, config.profits_address, ctx)

  }

  public fun user_fast_mint_selected(coin: Coin<SUI>, color: String, ctx: &mut TxContext): Get {

    let available_colors = get_hardcoded_available_colors();

    // TODO: check if we should re-organize the argument order
    mint_selected(coin, color, available_colors, PRICE_MINT_SELECTED, PROFITS_ADDRESS, ctx)
    
  }

  public fun user_mint_arbitrary(coin: Coin<SUI>, config: &Config, clock: &Clock, ctx: &mut TxContext): Get {

    assert!(coin::value(&coin) == config.price_mint_arbitrary, EInvalidCoinValue);

    let total_colors = vector::length(&config.available_colors);
    let index = get_arbitrary_number_in_range(total_colors, clock);
    let color = *vector::borrow(&config.available_colors, index);

    transfer::public_transfer(coin, config.profits_address);

    Get {
      id: object::new(ctx),
      color,
    }
  }

  public fun user_fast_mint_arbitrary(coin: Coin<SUI>, ctx: &mut TxContext): Get {

    assert!(coin::value(&coin) == PRICE_MINT_ARBITRARY, EInvalidCoinValue);

    let available_colors = get_hardcoded_available_colors();

    let total_colors = vector::length(&available_colors);
    let index = fast_get_arbitrary_number_in_range(total_colors, ctx);
    let color = *vector::borrow(&available_colors, index);

    transfer::public_transfer(coin, PROFITS_ADDRESS);

    Get {
      id: object::new(ctx),
      color,
    }
    
}

  public fun user_edit_color_with_ticket(get: &mut Get, edit_ticket: EditTicket) {
    let EditTicket { id, get_id, new_color } = edit_ticket;
    assert!(get_id == object::uid_to_inner(&get.id), EInvalidId);
    get.color = new_color;
    object::delete(id);
  }

  public fun user_edit_color_with_signature(
    get: &mut Get,
    new_color: String,
    expiration_timestamp: u64,
    signed_message: vector<u8>,
    config: &Config,
    clock: &Clock,
  ) {
    // Make sure signature timestamp has not expired.
    let current_timestamp = clock::timestamp_ms(clock);
    assert!(current_timestamp <= expiration_timestamp, ESignatureExpired);


    // Make sure the signature is valid.
    assert!(
      verify_update_signature(
        object::uid_to_inner(&get.id),
        new_color,
        expiration_timestamp,
        signed_message,
        config
      ), 
      EInvalidSignature
    );

    // Finally, update Get color
    get.color = new_color;
  }


  public fun user_put_for_color_change(get: Get, color_changer: &mut ColorChanger, ctx: &mut TxContext){

    let get_id = object::uid_to_inner(&get.id);
    let owner = tx_context::sender(ctx);

    let wrapped_get = WrappedGet { 
      owner,
      get,
    };

    event::emit( GetPutForColorChange { owner, get_id } );

    df::add<ID, WrappedGet>(&mut color_changer.id, get_id, wrapped_get);
  }

  public fun user_whitelist_claim(whitelist: &mut Whitelist, ctx: &mut TxContext): Get {
    let user_address = tx_context::sender(ctx);
    assert!(dof::exists_<address>(&whitelist.id, user_address), EUserNotWhitelisted);
    let get = dof::remove<address, Get>(&mut whitelist.id, user_address);
    get
  }

  // === Accessors ===

  public fun id(get: &Get): ID {
    object::uid_to_inner(&get.id)
  }

  public fun color(get: &Get): String {
    get.color
  }

  // === Helper functions ===

  // check if color is in available_colors field of config
  fun belongs_in_available_colors(available_colors: vector<String>, color: String): bool {
    // there are no sets in move. 
    // vec_set is equivalently O(n)
    // TODO: check if we could do this in O(1)
    let belongs_in_available_colors = false;
    let i = 0;
    let total = vector::length(&available_colors);
    while (i < total) {
      if (color == *vector::borrow(&available_colors, i)){
        belongs_in_available_colors = true;
        break
      };
      i = i + 1;
    };

    belongs_in_available_colors
  }

  fun get_hardcoded_available_colors(): vector<String> {
    let available_colors = vector[
      string::utf8(b"red"),
      string::utf8(b"orange"),
      string::utf8(b"yellow"),
      string::utf8(b"green"),
      string::utf8(b"blue"),
      string::utf8(b"indigo"),
      string::utf8(b"violet"),
    ];

    available_colors
  }

  fun mint_selected(
    coin: Coin<SUI>,
    color: String, 
    available_colors: vector<String>, 
    price_mint_selected: u64,
    profits_address: address,
    ctx: &mut TxContext
    ): Get {

    // make sure coin value is proper
    assert!(coin::value(&coin) == price_mint_selected, EInvalidCoinValue);

    transfer::public_transfer(coin, profits_address);

    mint(color, available_colors, ctx)
    
  }

  fun mint(
    color: String,
    available_colors: vector<String>,
    ctx: &mut TxContext,
  ): Get {

    assert!(belongs_in_available_colors(available_colors, color), EInvalidColor);

    Get {
      id: object::new(ctx),
      color,
    }

  }

  fun create_edit_ticket(
    get_id: ID,
    new_color: String, 
    available_colors: vector<String>, 
    ctx: &mut TxContext
    ): EditTicket {

    assert!(belongs_in_available_colors(available_colors, new_color), EInvalidColor);

    EditTicket {
      id: object::new(ctx),
      get_id,
      new_color
    }
      
  }

  // returns a number in range [0, n-1]
  fun fast_get_arbitrary_number_in_range(n: u64, ctx: &mut TxContext): u64 {

    let fresh_address = tx_context::fresh_object_address(ctx);

    // convert fresh_address to u256
    let fresh_u256 = address::to_u256(fresh_address);

    let number = fresh_u256 % (n as u256);
    (number as u64)
  }

  // returns a number in range [0, n-1]
  fun get_arbitrary_number_in_range(n: u64, clock: &Clock): u64{
    let current_timestamp = clock::timestamp_ms(clock);
    let number = current_timestamp % n;
    number
  }

  fun verify_update_signature(
    get_id: ID,
    new_color: String,
    expiration_timestamp: u64,
    signed_message: vector<u8>,
    config: &Config,
  ): bool {
    // Re-construct message that was signed.
    let msg: vector<u8> = vector::empty();
    vector::append(&mut msg, bcs::to_bytes<ID>(&get_id));
    vector::append(&mut msg, bcs::to_bytes<String>(&new_color));
    vector::append(&mut msg, bcs::to_bytes<u64>(&expiration_timestamp));
      
    // Return whether signature is valid or not.
    ed25519::ed25519_verify(&signed_message, &config.admin_public_key, &msg)
  }


  #[test_only]
  public fun init_for_test(ctx: &mut TxContext){
    init(GET {}, ctx);
  }

}