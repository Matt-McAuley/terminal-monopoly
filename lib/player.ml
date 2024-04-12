type t = {
  name : string;
  position : int;
  properties : Property.t list;
  money : int;
}

let empty = { name = ""; position = -1; properties = []; money = -1 }

let create_player name =
  {
    name = String.uppercase_ascii name;
    position = 0;
    properties = [];
    money = 1500;
  }

let is_empty player =
  player.name = "" && player.position = -1 && player.money = -1

let create_player name = { name; position = 0; properties = []; money = 1500 }
let get_name player = player.name
let get_position player = player.position

let set_position player new_pos =
  {
    name = player.name;
    position = new_pos;
    properties = player.properties;
    money = player.money;
  }

let get_properties player = player.properties

let add_property player property =
  {
    name = player.name;
    position = player.position;
    properties = property :: player.properties;
    money = player.money;
  }

let remove_property player property =
  {
    name = player.name;
    position = player.position;
    properties = List.filter (fun x -> x <> property) player.properties;
    money = player.money;
  }

let has_set player set_color : bool =
  let property_list = get_properties player in
  let properties_of_color =
    List.filter
      (fun property -> Property.get_color property = set_color)
      property_list
  in
  if set_color = "brown" || set_color = "dark_blue" then
    List.length properties_of_color = 2
  else List.length properties_of_color = 3

let get_money player = player.money

let add_money player money =
  {
    name = player.name;
    position = player.position;
    properties = player.properties;
    money = player.money + money;
  }

let remove_money player money =
  {
    name = player.name;
    position = player.position;
    properties = player.properties;
    money = player.money - money;
  }
