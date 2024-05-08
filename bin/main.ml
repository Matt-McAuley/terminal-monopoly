open Final_project
open Temp_properties
open ANSITerminal

let free_parking_money = ref 0

(** [print_logo] is the interface with the following format: Position on board:
    <users> Money for each player: <users> Properties owned: <users> printed to
    the console.*)
let print_logo () =
  let print_file filename =
    let file = open_in filename in
    try
      while true do
        let line = input_line file in
        print_endline line
      done
    with End_of_file -> close_in file
  in
  print_file "data/interface.txt"

(** [print_help] is the help menu that is printed when the user types "HELP"*)
let print_help () =
  let print_file filename =
    let file = open_in filename in
    try
      while true do
        let line = input_line file in
        print_endline line
      done
    with End_of_file -> close_in file
  in
  print_file "data/help.txt"

(** [plist_to_str plist] converts the property list [plist] to a string. *)
let plist_to_str (plist : Property.t list) =
  let lst = List.map (fun x -> Property.get_name x) plist in
  "(" ^ String.concat ", " lst ^ ")"

(** [player_info player] is the information of a [player] printed to the
    console. *)
let player_info player =
  if player = Player.empty then ""
  else
    let name = Player.get_name player in
    let position = string_of_int (Player.get_position player) in
    let money = string_of_int (Player.get_money player) in
    let properties = plist_to_str (Player.get_properties player) in
    let base_info =
      Printf.sprintf "%-10s: Position: %-2s | Money: %-5s | Properties: " name
        position money
    in
    let max_line_width = 80 in
    (* or any width you prefer *)
    if String.length base_info + String.length properties <= max_line_width then
      base_info ^ properties
    else
      let rec split_and_format str =
        if String.length str <= max_line_width then [ str ]
        else
          let part = String.sub str 0 max_line_width in
          let rest =
            String.sub str max_line_width (String.length str - max_line_width)
          in
          part :: split_and_format rest
      in
      let property_lines = split_and_format properties in
      let formatted_properties =
        String.concat
          ("\n" ^ String.make (String.length base_info) ' ')
          property_lines
      in
      base_info ^ formatted_properties

(** [pretty_info_printer p] is a helper function that prints the base
    information of player p on the terminal, using colors. *)
let pretty_info_printer p =
  if Player.is_empty p then ()
  else
    (* helper to remove the last element of a list *)
    let rec remove_last = function
      | [] -> failwith "Cannot remove from empty list"
      | _ :: [] -> []
      | x :: xs -> x :: remove_last xs
    in
    (* helper to return the last element of a list *)
    let rec return_last = function
      | [] -> failwith "empty list"
      | h :: [] -> h
      | _ :: t -> return_last t
    in
    (* iterable printer to print each property with color *)
    let print_property_color prop =
      print_string (Property.get_color prop) (Property.get_name prop ^ ", ")
    in
    let p_info = player_info p in
    let p_info_lst = String.split_on_char '|' p_info in
    print_string [] (String.concat "|" (remove_last p_info_lst));
    print_string [] "|";
    print_string [] (String.sub (return_last p_info_lst) 0 14);
    List.iter print_property_color (Player.get_properties p);
    print_string [] ")";
    print_endline ""

(** Print info about each player. If the player is empty, print an empty string *)
let print_info (p1 : Player.t) (p2 : Player.t) (p3 : Player.t) (p4 : Player.t) :
    unit =
  pretty_info_printer p1;
  pretty_info_printer p2;
  pretty_info_printer p3;
  pretty_info_printer p4

(** [make_player] makes a player with name according to user input. *)
let make_player () : Player.t =
  let p_name = read_line () in
  if p_name = "" then Player.empty else Player.create_player p_name

(** [roll_dice] is a random number between 2-12 as two dice rolls would be.*)
let roll_dice () =
  let () = Random.self_init () in
  2 + Random.int 10

(** [move_player_random player] is a [player] with position updated according to
    a random roll of two dice with values over 22 being truncated to fit on the
    board. *)
let move_player_random (player : Player.t) =
  let dice_roll = roll_dice () in
  Printf.printf "%s moved %d spots \n%!" (Player.get_name player) dice_roll;
  Player.(set_position player ((get_position player + dice_roll) mod 40))

(** [query_player player] queries the respective player to roll the dice *)
let query_player (player : Player.t) =
  Printf.printf "%s, Roll the dice by pressing \"ENTER\": %!"
    (Player.get_name player);
  let _ = read_line () in
  ()

(** [check_game_continue p1 p2 p3 p4] returns whether more than 1 players are
    left with money in their account.*)
let check_players_left p1 p2 p3 p4 =
  let player_left_increment player =
    if Player.get_money player <= 0 then 0 else 1
  in
  player_left_increment p1 + player_left_increment p2 + player_left_increment p3
  + player_left_increment p4
  > 1

(** [get_property_owner prop p1 p2 p3 p4] is an option of the owner if someone
    owns the property or None otherwise. *)
let get_property_owner prop p1 p2 p3 p4 =
  if List.mem prop (Player.get_properties p1) then Some p1
  else if List.mem prop (Player.get_properties p2) then Some p2
  else if List.mem prop (Player.get_properties p3) then Some p3
  else if List.mem prop (Player.get_properties p4) then Some p4
  else None

let check_property_at_pos pos = List.nth property_list pos

let owns_property prop player =
  if List.mem prop (Player.get_properties player) then true else false

(** [bought_railroad player property] upgrades the rent of the railroads when a
    player owns multiple. *)
let bought_railroad player property =
  if Property.get_color property = [ white ] then (
    let property_list = Player.get_properties player in
    let railroad_list =
      List.filter
        (fun property -> Property.get_color property = [ white ])
        property_list
    in
    List.iter (fun x -> print_endline (Property.get_name x)) property_list;
    let rec upgrade_to_level l p =
      if Property.get_level p < l then (
        Property.upgrade_level p;
        upgrade_to_level l p)
      else ()
    in
    List.iter (upgrade_to_level (List.length railroad_list)) railroad_list)
  else ()

(** [bought_utility player property] upgrades the rent of the utility properties
    when a player owns both. *)
let bought_utility player property =
  if Property.get_color property = [ default ] then
    let property_list = Player.get_properties player in
    let utility_list =
      List.filter
        (fun property -> Property.get_color property = [ default ])
        property_list
    in
    if List.length utility_list = 2 then
      List.iter Property.upgrade_level utility_list
    else ()
  else ()

(** [buy_property player property] allows the player to purchase the property
    they landed on if they choose to do so. If [player] does not have sufficient
    funds to purchase [property] they are told so*)
let buy_property (player : Player.t) (property : Property.t) =
  let prop_name = Property.get_name property in
  let prop_color = Property.get_color property in
  let prop_cost = string_of_int (Property.get_cost property) in
  ANSITerminal.(printf [] "Type \"b\" if you want to purchase ");
  ANSITerminal.(printf prop_color "%s" prop_name);
  ANSITerminal.(printf [] " for %s: " prop_cost);
  let the_input = read_line () in
  if the_input = "b" then begin
    bought_railroad player property;
    if Player.get_money player > Property.get_cost property then
      let () =
        if Player.has_set player prop_color then Property.upgrade_level property
        else ()
      in
      Player.add_property
        (Player.remove_money player (Property.get_cost property))
        property
    else begin
      Printf.printf "Insufficient funds to purchase %s" prop_name;
      let _ = read_line () in
      Printf.printf "Insufficient funds to purchase %s%!\n" prop_name;
      player
    end
  end
  else player

(** [pay_utility property] returns the rent that a player who lands on a utility
    pays. *)
let pay_utility property =
  if Property.get_level property = 2 then 10 * roll_dice ()
  else 4 * roll_dice ()

(** [pay_rent player owner property] is the tuple of [(player, owner)] where
    their respective bank accounts have been adjusted according to the rent.
    [player] pays [owner] the price of rent of [property] if they have
    sufficient funds. If [player] does not have enough money to cover rent, they
    pay their remaining money to [owner] and [player] is now bankrupt*)
let pay_rent (player : Player.t) (owner : Player.t) (property : Property.t) =
  let balance = Player.get_money player in
  let rent = Property.get_rent property in
  let price = if balance < rent then balance else rent in
  let new_player = Player.remove_money player price in
  let new_owner = Player.add_money owner price in
  let new_player =
    if Player.get_money new_player <= 0 then Player.empty else new_player
  in
  (new_player, new_owner)

(** [land_on_prop property player p1 p2 p3 p4] implements the functionality
    necessary when a player lands on property [property]. *)
let land_on_prop property player p1 p2 p3 p4 =
  let property_owner = get_property_owner property p1 p2 p3 p4 in
  match property_owner with
  | Some x ->
      if x = player then
        let () =
          Printf.printf "You landed on your own property, %s, phew!\n"
            (Property.get_name property)
        in
        let () = Printf.printf "\nPress \"ENTER\" to continue: %!" in
        let _ = read_line () in
        (player, x)
      else pay_rent player x property
  | None -> (buy_property player property, player)

(** [send_message message p1 p2 p3 p4 turn game_loop] sends the player a message
    and asks them to press enter before continuing. *)
let send_message message =
  Printf.printf "%s\n" message;
  Printf.printf "\nPress \"ENTER\" to continue: %!";
  let _ = read_line () in
  ()

(** [land_on_go p1 p2 p3 p4 turn game_loop] handles the player landing on the GO
    square. *)
let land_on_go player =
  send_message "You landed on GO, take a break!";
  player

(** [land_on_chest player] handles the player landing on the Community Chest
    squares. *)
let land_on_chest player = player

(** [land_on_chance player] handles the player landing on the Chance squares. *)
let land_on_chance player = player

(** [land_on_tax player] handles the player landing on the Tax squares. *)
let land_on_tax player tax =
  if Player.get_money player <= tax then begin
    free_parking_money := !free_parking_money + Player.get_money player;
    send_message "You landed on a tax space, you're out of money!";
    Player.empty
  end
  else begin
    free_parking_money := !free_parking_money + tax;
    send_message "You landed on a tax space!";
    Player.remove_money player tax
  end

(** [land_on_free_parking player] handles the player landing on the Free Parking
    square. *)
let land_on_free_parking player =
  let money = !free_parking_money in
  free_parking_money := 0;
  send_message "You landed on free parking, take some money!";
  Player.add_money player money

(** [land_on_GTJ player] handles the player landing on the Go To Jail square. *)
let land_on_GTJ player =
  send_message "You landed on Go To Jail, have fun!";
  let player = Player.set_jail player true in
  Player.set_position player 10

(** [land_on_jail player] handles the player landing on the Jail square but they
    are just visiting. *)
let land_on_jail player =
  send_message "You're visiting the Jail!";
  player

(** [special_square p1 p2 p3 p4 turn game_loop] handles landing on a unique game
    square that is not a property, railroad, or utility. *)
let special_square player property =
  let name = Property.get_name property in
  if name = "GO" then land_on_go player
  else if name = "Community Chest" then land_on_chest player
  else if name = "Chance" then land_on_chance player
  else if name = "Income Tax" then land_on_tax player 200
  else if name = "Luxury Tax" then land_on_tax player 100
  else if name = "Free Parking" then land_on_free_parking player
  else if name = "Go To Jail" then land_on_GTJ player
  else if name = "Jail" then land_on_jail player
  else (* Utilities *)
    player

(** [choose_roll player] handles if the [player] chose to roll the dice to get
    out of jail. *)
let choose_roll player =
  let () = Random.self_init () in
  let roll = Random.int 6 in
  if roll = 0 then
    let () = Printf.printf "You rolled doubles and made it out of Jail!\n" in
    Player.set_jail player false
  else
    let () = Printf.printf "You didn't roll doubles, you stay in Jail!" in
    if Player.get_rounds_in_jail player <= 2 then begin
      Printf.printf "\npress \"ENTER\" to continue: %!";
      let _ = read_line () in
      player
    end
    else
      let () =
        Printf.printf "\nThat was your third chance, you must pay $50!\n"
      in
      let player = Player.remove_money player 50 in
      if Player.get_money player <= 0 then Player.empty
      else Player.set_jail player false

(** [handle_jail player] checks whether or not a [player] is in jail and deals
    with it accordingly. *)
let handle_jail player =
  if not (Player.is_in_jail player) then player
  else
    let player =
      Player.set_rounds_in_jail player (Player.get_rounds_in_jail player + 1)
    in
    Printf.printf
      "%s, you are in jail, type 'roll' to roll the dice to get out. You need \
       to get doubles to do so or else you stay in jail. Or you can pay $50 \
       dollars to exit jail right now by typing 'pay'. If you are still in \
       jail after 3 rolls you must pay the $50."
      (Player.get_name player);
    let rec loop () =
      Printf.printf "\nType your choice and press \"ENTER\" to continue: %!";
      let choice = read_line () in
      if choice = "roll" then choose_roll player
      else if choice = "pay" then begin
        Printf.printf "\n%s paid their way out of Jail!\n"
          (Player.get_name player);
        let player = Player.remove_money player 50 in
        if Player.get_money player <= 0 then Player.empty
        else Player.set_jail player false
      end
      else loop ()
    in
    loop ()

(** [get_property_by_name prop_name] is the property with the [prop_name] inside
    of the global property list. *)
let get_property_by_name prop_name =
  match
    List.filter
      (fun x ->
        String.lowercase_ascii (Property.get_name x)
        = String.lowercase_ascii prop_name)
      Temp_properties.property_list
  with
  | [] -> None
  | h :: _ -> Some h

(** [query_house player] runs once a player has a color set of any kind. It asks
    them if they would like to buy a house on their properties and then
    continues accordingly, changing the property level and the [player]'s money.
    It also accounts for incorrect property names, a property that is not owned,
    and skipping for the current turn *)
let rec query_house player =
  print_string []
    "If you would like to buy a house, enter the name of the property, \
     otherwise type 'no': ";
  let response = read_line () in
  if String.lowercase_ascii response = "no" then player
  else
    match get_property_by_name response with
    | None ->
        print_endline "There is no property by that name!";
        query_house player
    | Some prop ->
        if Player.has_set player (Property.get_color prop) then
          if Player.get_money player > Property.get_house_cost prop then begin
            print_string [] (Player.get_name player ^ " bought a house on ");
            print_string (Property.get_color prop) (Property.get_name prop);
            print_endline ".";
            Property.upgrade_level prop;
            Printf.printf "The rent of the property is now %i %!\n"
              (Property.get_rent prop);
            Printf.printf "Press \"ENTER\" to continue: %!";
            let _ = read_line () in
            Player.remove_money player (Property.get_house_cost prop)
          end
          else begin
            print_endline "You do not have enough money!";
            query_house player
          end
        else begin
          print_endline "You do not own that property set!";
          query_house player
        end

let check_set player =
  if Player.has_any_set player then query_house player else player

(** [pass_go p old_pos] adds 200 money to the player [p] if they have passed go. *)
let pass_go p old_pos =
  if Player.get_position p < old_pos then Player.add_money p 200 else p

(** [p1_turn p1 p2 p3 p4 game_loop] is a helper function to the game loop when
    it is p1's turn. *)
let p1_turn p1 p2 p3 p4 turn game_loop =
  if p1 = Player.empty then game_loop p1 p2 p3 p4 (turn + 1)
  else
    let p1 = handle_jail p1 in
    if not (Player.is_in_jail p1) then begin
      query_player p1;
      let old_pos = Player.get_position p1 in
      let p1 = move_player_random p1 in
      let p1 = pass_go p1 old_pos in
      let property = check_property_at_pos (Player.get_position p1) in
      if Property.get_color property = [ default ] then
        let p1 = special_square p1 property in
        game_loop p1 p2 p3 p4 (turn + 1)
      else
        let result = land_on_prop property p1 p1 p2 p3 p4 in
        let p1 = fst result in
        let p1 = check_set p1 in
        if owns_property property p1 then game_loop p1 p2 p3 p4 (turn + 1)
        else if owns_property property p2 then
          game_loop p1 (snd result) p3 p4 (turn + 1)
        else if owns_property property p3 then
          game_loop p1 p2 (snd result) p4 (turn + 1)
        else if owns_property property p4 then
          game_loop p1 p2 p3 (snd result) (turn + 1)
        else game_loop p1 p2 p3 p4 (turn + 1)
    end
    else game_loop p1 p2 p3 p4 (turn + 1)

(** [p2_turn p1 p2 p3 p4 game_loop] is a helper function to the game loop when
    it is p2's turn. *)
let p2_turn p1 p2 p3 p4 turn game_loop =
  if p2 = Player.empty then game_loop p1 p2 p3 p4 (turn + 1)
  else
    let p2 = handle_jail p2 in
    if not (Player.is_in_jail p2) then begin
      query_player p2;
      let old_pos = Player.get_position p2 in
      let p2 = move_player_random p2 in
      let p2 = pass_go p2 old_pos in
      let property = check_property_at_pos (Player.get_position p2) in
      if Property.get_color property = [ default ] then
        let p2 = special_square p2 property in
        game_loop p1 p2 p3 p4 (turn + 1)
      else
        let result = land_on_prop property p2 p1 p2 p3 p4 in
        let p2 = fst result in
        let p2 = check_set p2 in
        if owns_property property p2 then game_loop p1 p2 p3 p4 (turn + 1)
        else if owns_property property p1 then
          game_loop (snd result) p2 p3 p4 (turn + 1)
        else if owns_property property p3 then
          game_loop p1 p2 (snd result) p4 (turn + 1)
        else if owns_property property p4 then
          game_loop p1 p2 p3 (snd result) (turn + 1)
        else game_loop p1 p2 p3 p4 (turn + 1)
    end
    else game_loop p1 p2 p3 p4 (turn + 1)

(** [p3_turn p1 p2 p3 p4 game_loop] is a helper function to the game loop when
    it is p3's turn. *)
let p3_turn p1 p2 p3 p4 turn game_loop =
  if p3 = Player.empty then game_loop p1 p2 p3 p4 (turn + 1)
  else
    let p3 = handle_jail p3 in
    if not (Player.is_in_jail p3) then begin
      query_player p3;
      let old_pos = Player.get_position p3 in
      let p3 = move_player_random p3 in
      let p3 = pass_go p3 old_pos in
      let property = check_property_at_pos (Player.get_position p3) in
      if Property.get_color property = [ default ] then
        let p3 = special_square p3 property in
        game_loop p1 p2 p3 p4 (turn + 1)
      else
        let result = land_on_prop property p3 p1 p2 p3 p4 in
        let p3 = fst result in
        let p3 = check_set p3 in
        if owns_property property p3 then game_loop p1 p2 p3 p4 (turn + 1)
        else if owns_property property p1 then
          game_loop (snd result) p2 p3 p4 (turn + 1)
        else if owns_property property p2 then
          game_loop p1 (snd result) p3 p4 (turn + 1)
        else if owns_property property p4 then
          game_loop p1 p2 p3 (snd result) (turn + 1)
        else game_loop p1 p2 p3 p4 (turn + 1)
    end
    else game_loop p1 p2 p3 p4 (turn + 1)

(** [p4_turn p1 p2 p3 p4 game_loop] is a helper function to the game loop when
    it is p4's turn. *)
let p4_turn p1 p2 p3 p4 turn game_loop =
  if p4 = Player.empty then game_loop p1 p2 p3 p4 (turn + 1)
  else
    let p2 = handle_jail p4 in
    if not (Player.is_in_jail p4) then begin
      query_player p4;
      let old_pos = Player.get_position p4 in
      let p4 = move_player_random p4 in
      let p4 = pass_go p4 old_pos in
      let property = check_property_at_pos (Player.get_position p4) in
      if Property.get_color property = [ default ] then
        let p4 = special_square p4 property in
        game_loop p1 p2 p3 p4 (turn + 1)
      else
        let result = land_on_prop property p4 p1 p2 p3 p4 in
        let p4 = fst result in
        let p4 = check_set p4 in
        if owns_property property p4 then game_loop p1 p2 p3 p4 (turn + 1)
        else if owns_property property p1 then
          game_loop (snd result) p2 p3 p4 (turn + 1)
        else if owns_property property p2 then
          game_loop p1 (snd result) p3 p4 (turn + 1)
        else if owns_property property p3 then
          game_loop p1 p2 (snd result) p4 (turn + 1)
        else game_loop p1 p2 p3 p4 (turn + 1)
    end
    else game_loop p1 p2 p3 p4 (turn + 1)

(** [game_loop p1 p2 p3 p4 turn] continously runs the game until it is over.
    [turn] keeps track of which player's turn it is. *)
let rec game_loop (p1 : Player.t) (p2 : Player.t) (p3 : Player.t)
    (p4 : Player.t) turn =
  if not (check_players_left p1 p2 p3 p4) then ()
  else
    let _ = Sys.command "clear" in
    print_info p1 p2 p3 p4;
    print_endline "";
    if turn mod 4 = 1 then p1_turn p1 p2 p3 p4 turn game_loop
    else if turn mod 4 = 2 then p2_turn p1 p2 p3 p4 turn game_loop
    else if turn mod 4 = 3 then p3_turn p1 p2 p3 p4 turn game_loop
    else p4_turn p1 p2 p3 p4 turn game_loop

(** [run_game p1 p2 p3 p4] gets the game started by initiating the game loop
    function on turn = 1. *)
let run_game p1 p2 p3 p4 = game_loop p1 p2 p3 p4 1

(** Begins game by asking player to type start*)
let () =
  (* Terminal.setup_term (); Terminal.input_non_canonique_restart_unblocked
     ~when_unblocked:handle_key stdin; Terminal.restore_term () *)
  print_logo ();
  let () = print_string [] "\nPress \"ENTER\" to begin the game: " in
  let the_input = read_line () in
  if the_input = "" then begin
    (* Create player 1*)
    let () = print_string [] "Player1 type your name: " in
    let p1 = make_player () in
    (* Create player 2*)
    let () = print_string [] "Player2 type your name: " in
    let p2 = make_player () in
    (* Create player 3*)
    let () = print_string [] "Player3 type your name: " in
    let p3 = make_player () in
    (* Create player 3*)
    let () = print_string [] "Player4 type your name: " in
    let p4 = make_player () in
    let () = run_game p1 p2 p3 p4 in
    print_endline "Gameover"
  end
  else if the_input = "HELP" then begin
    let _ = Sys.command "clear" in
    print_help ()
  end
