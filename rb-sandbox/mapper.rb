require 'json'

MAPS = File.open('data/bf3/bdatjs/sys/SYS_MapList.json') { |f| JSON.parse(f.read) }.then { |res| [res["schema"], res["rows"]] }
LOCATIONS_DLC04 = File.open('data/bf3/bdatjs/dlc/SYS_GimmickLocation_dlc04.json') { |f| JSON.parse(f.read) }.then { |res| [res["schema"], res["rows"]] }
MAP40_LOCATIONS = File.open('data/bf3/bdatjs/dlc/ma40a_GMK_Location.json') { |f| JSON.parse(f.read) }.then { |res| [res["schema"], res["rows"]] }
LOCATION_NAMES = File.open('data/bf3/bdatjs/gb/game/system/msg_location_name.json') { |f| JSON.parse(f.read) }.then { |res| [res["schema"], res["rows"]] }
MAP_RESOURCES = File.open('data/bf3/bdatjs/sys/RSC_MapFile.json') { |f| JSON.parse(f.read) }.then { |res| [res["schema"], res["rows"]] }

def get_map_info id
  xmap = MAPS[1].find { |m| m["$id"] == id }
  resources = MAP_RESOURCES[1].find { |r| r["$id"] == id }
  name = LOCATION_NAMES[1].find { |n| n["$id"] == xmap["Name"] }
  {    
    id: id,
    xmap: xmap,
    resources: resources,
    name: name,    
  }
end

def obj_to_array obj, schema
  [if obj.nil? then nil else obj["$id"] end] + schema.map { |s| if obj.nil? then nil else obj[s["name"]] end }
end

def map_csv map_info
  row = []
  row += obj_to_array(map_info[:xmap], MAPS[0])
  row += obj_to_array(map_info[:name], LOCATION_NAMES[0])
  row += obj_to_array(map_info[:resources], MAP_RESOURCES[0])
end
  
def maps_csv map_infos
  headers = ([{"name" => "$id"}] + MAPS[0] + [{"name" => "$nid"}] + LOCATION_NAMES[0] + [{"name" => "$rid"}] + MAP_RESOURCES[0]).map { |s| s["name"] }
  rows = [headers] + map_infos.map { |m| map_csv(m) }
  rows.map { |r| r.join("|") }.join("\n")
end

def pprint obj
  puts JSON.pretty_generate(obj)
end

MAPS[1].map { |m| m["$id"] }.map { |id| get_map_info(id) }.then { |maps| maps_csv(maps) }.then { |csv| File.write("maps.csv", csv) }
