module get_labs::get{

  use std::string::{Self, String};
  use std::vector;

  use sui::dynamic_object_field as dof;
  use sui::coin::{Self, Coin};
  use sui::clock::{Self, Clock};
  use sui::display;
  use sui::package;
  use sui::object::{Self, ID, UID};
  use sui::transfer;
  use sui::tx_context::{Self, TxContext};
  use sui::sui::SUI;

  const ADMIN_ADDRESS: address = @0x10;

  const EInvalidColor: u64 = 0;
  const EInvalidCoinValue: u64 = 1;
  const EInvalidId: u64 = 2;
  const EUserAlreadyWhitelisted: u64 = 3;
  const EUserNotWhitelisted: u64 = 4;

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
    profits_address: address,
    colors_available: vector<String>,
    price_mint_selected: u64,
    price_mint_random: u64,
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

  // wrapped Get object
  struct WrappedGet has key, store {
    id: UID,
    owner: address,
    get: Get,
  }

  // --- Events ---
  // TODO: add a ColorChange event


  fun init(otw: GET, ctx: &mut TxContext){

    // claim publisher
    let publisher = package::claim(otw, ctx);

    // create display
    let keys = vector[string::utf8(b"image_url")];
    let values = vector[string::utf8(b"https://placehold.co/600x600/{color}/{color}")];
    let display = display::new_with_fields<Get>(&publisher, keys, values, ctx);

    // initialize Config struct
    let colors_available = vector[
      string::utf8(b"red"),
      string::utf8(b"orange"),
      string::utf8(b"yellow"),
      string::utf8(b"green"),
      string::utf8(b"blue"),
      string::utf8(b"indigo"),
      string::utf8(b"violet"),
    ];

    let config = Config {
      id: object::new(ctx),
      profits_address: ADMIN_ADDRESS,
      colors_available,
      price_mint_selected: 10_000_000,
      price_mint_random: 5_000_000,
    };

    let admin_cap = AdminCap {id: object::new(ctx)};

    let whitelist = Whitelist { id: object::new(ctx) };

    transfer::share_object(config);
    transfer::share_object(whitelist);

    let sender = tx_context::sender(ctx);

    transfer::public_transfer(display, sender);
    transfer::public_transfer(publisher, sender);
    transfer::public_transfer(admin_cap, sender);
  }

  // === Admin-only functions ===

  /// Admin-only function, mints and returns a Get object
  /// Can mint arbitrary colors
  public fun admin_mint(_: &AdminCap, color: String, ctx: &mut TxContext): Get {
    Get {
      id: object::new(ctx),
      color,
    }
  }

  public fun admin_create_edit_ticket(_: &AdminCap, get_id: ID, new_color: String, ctx: &mut TxContext): EditTicket {
    EditTicket {
      id: object::new(ctx),
      get_id,
      new_color
    }
  }

  // TODO: function to alter colors
  // TODO: function to alter prices
  // TODO: function to alter admin address
  // TODO: function to create more admin caps

  public fun admin_whitelist_add(_: &AdminCap, whitelist: &mut Whitelist, get: Get, user_address: address){
    assert!(!dof::exists_<address>(&whitelist.id, user_address), EUserAlreadyWhitelisted);
    dof::add<address, Get>(&mut whitelist.id, user_address, get);
  }

  // === User functions ===

  public fun mint_selected(coin: Coin<SUI>, color: String, config: &Config, ctx: &mut TxContext): Get {
    // make sure coin value is proper
    assert!(coin::value(&coin) == config.price_mint_selected, EInvalidCoinValue);

    // check if color is in colors_available field of config
    // there are no sets in move. 
    // vec_set is equivalently O(n)
    // TODO: check if we could do this in O(1)
    let belongs_in_colors_available = false;
    let i = 0;
    let total = vector::length(&config.colors_available);
    while (i < total) {
      if (color == *vector::borrow(&config.colors_available, i)){
        belongs_in_colors_available = true;
        break
      };
      i = i + 1;
    };

    assert!(belongs_in_colors_available, EInvalidColor);

    transfer::public_transfer(coin, config.profits_address);
    
    Get {
      id: object::new(ctx),
      color,
    }
  }

  public fun mint_random(coin: Coin<SUI>, config: &Config, clock: &Clock, ctx: &mut TxContext): Get {
    assert!(coin::value(&coin) == config.price_mint_random, EInvalidCoinValue);

    let total_colors = vector::length(&config.colors_available);
    let index = get_random_in_range(total_colors, clock);
    let color = *vector::borrow(&config.colors_available, index);

    transfer::public_transfer(coin, config.profits_address);

    Get {
      id: object::new(ctx),
      color,
    }
  }

  public fun edit_color_with_ticket(get: &mut Get, edit_ticket: EditTicket) {
    let EditTicket { id, get_id, new_color } = edit_ticket;
    assert!(get_id == object::uid_to_inner(&get.id), EInvalidId);
    get.color = new_color;
    object::delete(id);
  }

  // TODO: the following function
  // public fun put_for_color_change(get: Get, color_changer: &mut ColorChanger){}

  public fun whitelist_claim(whitelist: &mut Whitelist, ctx: &mut TxContext): Get {
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

  // returns a number in range [0, n-1]
  // TODO: make this less predictable
  fun get_random_in_range(n: u64, clock: &Clock): u64{
    let current_timestamp = clock::timestamp_ms(clock);
    let number = current_timestamp % n;
    number
  }


  #[test_only]
  public fun init_for_test(ctx: &mut TxContext){
    init(GET {}, ctx);
  }

}