#[test_only]
module get_labs::test_get{

  // use std::debug;
  use std::string::{Self, String};

  use sui::coin;
  use sui::clock::{Self, Clock};
  // use sui::object::ID;
  use sui::sui::SUI;
  use sui::test_scenario::{Self as ts, Scenario};
  use sui::transfer;

  use get_labs::get::{Self, Config, Get, AdminCap, EditTicket, Whitelist, EInvalidCoinValue, EInvalidColor, EInvalidId, EUserAlreadyWhitelisted, EUserNotWhitelisted};

  const EColorNotSetProperly: u64 = 0;
  const EColorNotUpdatedProperly: u64 = 1;

  const ADMIN: address = @0x10;
  const USER: address = @0x11;

  #[test]
  fun test_mint_selected(){

    let scenario_val = ts::begin(ADMIN);
    let scenario = &mut scenario_val;

    get::init_for_test(ts::ctx(scenario));

    // next transaction by user to mint a Get
    ts::next_tx(scenario, USER);
    let get = mint_selected(scenario, 10_000_000, string::utf8(b"red"));
    transfer::public_transfer(get, USER);

    ts::end(scenario_val);

  }

  #[test]
  #[expected_failure(abort_code = EInvalidCoinValue)]
  fun test_mint_selected_invalid_coin(){

    let scenario_val = ts::begin(ADMIN);
    let scenario = &mut scenario_val;

    get::init_for_test(ts::ctx(scenario));

    // next transaction by user to mint a Get with invalid coin value
    ts::next_tx(scenario, USER);
    let get = mint_selected(scenario, 3_000_000, string::utf8(b"red"));
    transfer::public_transfer(get, USER);

    ts::end(scenario_val);

  }

  #[test]
  #[expected_failure(abort_code = EInvalidColor)]
    fun test_mint_selected_invalid_color(){

    let scenario_val = ts::begin(ADMIN);
    let scenario = &mut scenario_val;

    get::init_for_test(ts::ctx(scenario));

    // next transaction by user to mint a Get with invalid color
    ts::next_tx(scenario, USER);
    let get = mint_selected(scenario, 10_000_000, string::utf8(b"magenta"));
    transfer::public_transfer(get, USER);

    ts::end(scenario_val);
  }

  #[test]
  // if we change default (set in init) colors stored in config, this test should change too
  fun test_mint_arbitrary(){

    let scenario_val = ts::begin(ADMIN);
    let scenario = &mut scenario_val;

    get::init_for_test(ts::ctx(scenario));

    // next transaction by user to mint a Get with arbitrary color
    ts::next_tx(scenario, USER);
    let clock = clock::create_for_testing(ts::ctx(scenario));
    clock::increment_for_testing(&mut clock, 1_000_000_000);
    let get = mint_arbitrary(scenario, 5_000_000, &clock);
    // make sure that color is color in index 4 -> blue
    assert!(get::color(&get) == string::utf8(b"violet"), EColorNotSetProperly);
    
    transfer::public_transfer(get, USER);

    clock::destroy_for_testing(clock);

    ts::end(scenario_val);

  }

  #[test]
  #[expected_failure(abort_code = EInvalidCoinValue)]
  fun test_mint_arbitrary_invalid_coin(){

    let scenario_val = ts::begin(ADMIN);
    let scenario = &mut scenario_val;

    get::init_for_test(ts::ctx(scenario));

    // next transaction by user to mint a Get with arbitrary color
    ts::next_tx(scenario, USER);
    let clock = clock::create_for_testing(ts::ctx(scenario));
    clock::increment_for_testing(&mut clock, 1_000_000_000);
    let get = mint_arbitrary(scenario, 2_000_000, &clock);
    // make sure that color is color in index 4 -> blue
    assert!(get::color(&get) == string::utf8(b"violet"), EColorNotSetProperly);
    
    transfer::public_transfer(get, USER);

    clock::destroy_for_testing(clock);

    ts::end(scenario_val);

  }

  #[test]
  fun test_edit_color_with_ticket(){
    let scenario_val = ts::begin(ADMIN);
    let scenario = &mut scenario_val;

    get::init_for_test(ts::ctx(scenario));

    // next transaction by admin to mint a Get and send it to the user
    ts::next_tx(scenario, ADMIN);
    let get = admin_mint(scenario, string::utf8(b"red"));
    // keep the get id for later
    let get_id = get::id(&get);
    transfer::public_transfer(get, USER);

    // next transaction by admin to create an edit ticket for the Get of the user
    ts::next_tx(scenario, ADMIN);
    let admin_cap = ts::take_from_sender<AdminCap>(scenario);
    let config = ts::take_shared<Config>(scenario);

    let edit_ticket = get::admin_create_edit_ticket(&admin_cap, get_id, string::utf8(b"indigo"), &config, ts::ctx(scenario));
    transfer::public_transfer(edit_ticket, USER);

    ts::return_shared(config);
    ts::return_to_sender(scenario, admin_cap);

    // next transaction by user to update their color using the edit ticket
    ts::next_tx(scenario, USER);
    let edit_ticket = ts::take_from_sender<EditTicket>(scenario);
    let get = ts::take_from_sender<Get>(scenario);
    get::user_edit_color_with_ticket(&mut get, edit_ticket);
    ts::return_to_sender(scenario, get);

    // next transaction by user to make sure color was updated properly
    ts::next_tx(scenario, USER);
    let get = ts::take_from_sender<Get>(scenario);
    assert!(get::color(&get) == string::utf8(b"indigo"), EColorNotUpdatedProperly);
    ts::return_to_sender(scenario, get);

    ts::end(scenario_val);
    
    
  }

  #[test]
  #[expected_failure(abort_code = EInvalidId)]
  fun test_edit_color_with_wrong_ticket(){
    let other_user = @0x12;

    let scenario_val = ts::begin(ADMIN);
    let scenario = &mut scenario_val;

    get::init_for_test(ts::ctx(scenario));

    // next transaction by admin to mint a Get and send it to the user
    ts::next_tx(scenario, ADMIN);
    let get = admin_mint(scenario, string::utf8(b"red"));
    // keep the get id for later
    let get_id = get::id(&get);
    transfer::public_transfer(get, USER);


    // next transaction by admin to mint another Get and send it to the other user
    ts::next_tx(scenario, ADMIN);
    let other_get = admin_mint(scenario, string::utf8(b"yellow"));
    transfer::public_transfer(other_get, other_user);

    // next transaction by admin to create an edit ticket for the Get of the user
    ts::next_tx(scenario, ADMIN);
    let admin_cap = ts::take_from_sender<AdminCap>(scenario);
    let config = ts::take_shared<Config>(scenario);

    let edit_ticket = get::admin_create_edit_ticket(&admin_cap, get_id, string::utf8(b"indigo"), &config, ts::ctx(scenario));
    transfer::public_transfer(edit_ticket, USER);

    ts::return_shared(config);
    ts::return_to_sender(scenario, admin_cap);

    // next transaction by user that sends their edit ticket to another user
    ts::next_tx(scenario, USER);
    let edit_ticket = ts::take_from_sender<EditTicket>(scenario);
    transfer::public_transfer(edit_ticket, other_user);


    // next transaction by other_user to update their color using the edit ticket
    ts::next_tx(scenario, other_user);
    let edit_ticket = ts::take_from_sender<EditTicket>(scenario);
    let other_get = ts::take_from_sender<Get>(scenario);
    get::user_edit_color_with_ticket(&mut other_get, edit_ticket);
    ts::return_to_sender(scenario, other_get);

    ts::end(scenario_val);
  }

  #[test]
  fun test_whitelist_add(){

    let scenario_val = ts::begin(ADMIN);
    let scenario = &mut scenario_val;

    get::init_for_test(ts::ctx(scenario));

    ts::next_tx(scenario, ADMIN);
    admin_mint_and_whitelist_add(scenario, USER);

    ts::end(scenario_val);
  }

  #[test]
  #[expected_failure(abort_code = EUserAlreadyWhitelisted)]
  fun test_whitelist_user_already_whitelisted(){
    let scenario_val = ts::begin(ADMIN);
    let scenario = &mut scenario_val;

    get::init_for_test(ts::ctx(scenario));

    ts::next_tx(scenario, ADMIN);
    admin_mint_and_whitelist_add(scenario, USER);

    ts::next_tx(scenario, ADMIN);
    admin_mint_and_whitelist_add(scenario, USER);

    ts::end(scenario_val);
  }

  #[test]
  fun test_whitelist_claim() {

    let scenario_val = ts::begin(ADMIN);
    let scenario = &mut scenario_val;

    get::init_for_test(ts::ctx(scenario));

    ts::next_tx(scenario, ADMIN);
    admin_mint_and_whitelist_add(scenario, USER);

    ts::next_tx(scenario, USER);
    let whitelist = ts::take_shared<Whitelist>(scenario);
    let get = get::user_whitelist_claim(&mut whitelist, ts::ctx(scenario));
    ts::return_shared(whitelist);
    transfer::public_transfer(get, USER);

    ts::end(scenario_val);
  }

  #[test]
  #[expected_failure(abort_code = EUserNotWhitelisted)]
  fun test_claim_when_not_whitelisted(){

    let scenario_val = ts::begin(ADMIN);
    let scenario = &mut scenario_val;

    get::init_for_test(ts::ctx(scenario));

    ts::next_tx(scenario, USER);
    let whitelist = ts::take_shared<Whitelist>(scenario);
    let get = get::user_whitelist_claim(&mut whitelist, ts::ctx(scenario));
    ts::return_shared(whitelist);
    transfer::public_transfer(get, USER);

    ts::end(scenario_val);

  }

  #[test]
  fun test_update_with_signature(){

    let scenario_val = ts::begin(ADMIN);
    let scenario = &mut scenario_val;

    get::init_for_test(ts::ctx(scenario));

    // next transaction by ADMIN to set their public key in config
    ts::next_tx(scenario, ADMIN);
    let config = ts::take_shared<Config>(scenario);
    let admin_cap = ts::take_from_sender<AdminCap>(scenario);

    let admin_pk = vector<u8>[  
      234, 117, 170, 211,   4, 163,  98,  28,
      9, 166,  17, 253, 102,  80, 209,  36,
      106, 233, 253, 206, 212,  66,  31, 225,
      7, 123,  96, 194, 203,  88, 213, 214];
    get::admin_edit_public_key(&admin_cap, admin_pk, &mut config);

    ts::return_to_sender(scenario, admin_cap);
    ts::return_shared(config);

    // admin mints a get and sends it to user
    ts::next_tx(scenario, ADMIN);
    let get = admin_fast_mint(scenario, string::utf8(b"red"));
    // The two lines below are to get the id of a Get
    // let get_id = get::id(&get);
    // debug::print<ID>(&get_id);
    // send get to user
    transfer::public_transfer(get, USER);

    // user now updates their get
    ts::next_tx(scenario, USER);
    let clock = clock::create_for_testing(ts::ctx(scenario));
    let get = ts::take_from_sender<Get>(scenario);
    let config = ts::take_shared<Config>(scenario);

    let new_color = string::utf8(b"indigo");
    let expiration_timestamp = 60000; 
    let signed_message = vector[  
      147, 159,   3, 217,  56, 141, 124, 129,   0,  78, 184,
      123, 228,  15,  57, 202, 202, 148,  74,  15, 127,  67,
      230, 255, 173, 144, 126, 179, 245,  84,  99,  86,  86,
      99, 203, 224, 109, 125, 183, 215, 226, 220,  59,  70,
      49,  34, 194,  38, 189,  79,  81,  77,  12, 124,  67,
      152, 229,   9, 115,  33, 243,  85,  39,  13];
    get::user_edit_color_with_signature(
      &mut get,
      new_color,
      expiration_timestamp,
      signed_message,
      &config,
      &clock,
    );

    ts::return_to_sender(scenario, get);
    ts::return_shared(config);

    clock::destroy_for_testing(clock);

    // next transaction by user to make sure their Get is updated
    ts::next_tx(scenario, USER);
    let get = ts::take_from_sender<Get>(scenario);
    assert!(get::color(&get) == string::utf8(b"indigo"), EColorNotUpdatedProperly);
    ts::return_to_sender(scenario, get);

    ts::end(scenario_val);
  }

  

  // === helper functions for testing ===

  fun mint_selected(scenario: &mut Scenario, coin_value: u64, color: String): Get {

    let config = ts::take_shared<Config>(scenario);

    let coin = coin::mint_for_testing<SUI>(coin_value, ts::ctx(scenario));

    let get = get::user_mint_selected(coin, color, &config, ts::ctx(scenario));

    ts::return_shared(config);

    get
  }

  fun mint_arbitrary(scenario: &mut Scenario, coin_value: u64, clock: &Clock): Get {

    let config = ts::take_shared<Config>(scenario);

    let coin = coin::mint_for_testing<SUI>(coin_value, ts::ctx(scenario));
    let get = get::user_mint_arbitrary(coin, &config, clock, ts::ctx(scenario));

    ts::return_shared(config);

    get
  }

  fun admin_mint(scenario: &mut Scenario, color: String): Get {

    let admin_cap = ts::take_from_address<AdminCap>(scenario, ADMIN);
    let config = ts::take_shared<Config>(scenario);

    let get = get::admin_mint(&admin_cap, color, &config, ts::ctx(scenario));

    ts::return_to_address(ADMIN, admin_cap);
    ts::return_shared(config);

    get
  }

  fun admin_fast_mint(scenario: &mut Scenario, color: String): Get {

    let admin_cap = ts::take_from_address<AdminCap>(scenario, ADMIN);

    let get = get::admin_fast_mint(&admin_cap, color, ts::ctx(scenario));

    ts::return_to_address(ADMIN, admin_cap);

    get
  }

  fun admin_mint_and_whitelist_add(scenario: &mut Scenario, user_address: address){

    let config = ts::take_shared<Config>(scenario);
    let whitelist = ts::take_shared<Whitelist>(scenario);
    let admin_cap = ts::take_from_sender<AdminCap>(scenario);
    
    let get = get::admin_mint(&admin_cap, string::utf8(b"red"), &config, ts::ctx(scenario));
    get::admin_whitelist_add(&admin_cap, &mut whitelist, get, user_address);

    ts::return_shared(config);
    ts::return_shared(whitelist);
    ts::return_to_sender(scenario, admin_cap);
  }
}