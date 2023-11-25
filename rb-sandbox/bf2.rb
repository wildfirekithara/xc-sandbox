# WIP

require 'json'
require 'colorize'


module BF2
  BDAT_BASE = "./data/bf2/bdatjs"
  EVENT_MESSAGES = {}

  def self.load_json path
    bdat_path = path.split("/").drop(4).join("/").split(".")[0..-2].join(".")
    File.open(path) { |f| JSON.parse(f.read) }.then { |res| [res["schema"], res["rows"], bdat_path] }
  end

  def self.load_bdat path
    load_json File.join(BDAT_BASE, "#{path}.json")
  end

  REGION_NAMES = {
    "ma45a" => "First City (Indoors)",
    "ma46a" => "First City (Outdoors)",
    "ma59a" => "First City Hospital",
    "ma60a" => "Forest",
    "ma65a" => "Epilogue",
  }

  EVENT_LISTS = [
    {
      pack: :base,
      data: load_bdat("evt/EVT_listEv"),
      type: "ev",
    },
    {
      pack: :base,
      data: load_bdat("evt/EVT_listFev"),
      type: "qst",
    },
    {
      pack: :base,
      data: load_bdat("evt/EVT_listQst"),
      type: "qst",
    },
    {
      pack: :base,
      data: load_bdat("evt/EVT_listTlk"),
      type: "qst",
    },
    {
      pack: :dlc04,
      data: load_bdat("evt/D1C136A1"),
      type: "ev",
    },
  ]

  EVENT_LIST = EVENT_LISTS.map { |el| el[:data][1] }.flatten

  EVENT_THEATRE_SCENES = {
    base: load_bdat("mnu/MNU_EventTheater_scn"),
    dlc04: load_bdat("mnu/MNU_EventTheater_scn_DLC04"),
  }

  EVENT_SCENE_NAMES = load_bdat "gb/game/menu/msg_mnu_event_name"

  def self.map_id2pack map_id
    if map_id.start_with?("ma4")
      :dlc04
    else
      :base
    end
  end

  def self.evid2pack evid
    if evid.start_with?("ev1") || evid.start_with?("ev4")
      :dlc04
    else
      :base
    end
  end

  MAPS = load_bdat "sys/SYS_MapList"
  LOCATION_NAMES = load_bdat "gb/game/system/msg_location_name"
  MAP_RESOURCES = load_bdat "sys/RSC_MapFile"

  # GMK_LOCATIONS = {
  #   base: load_bdat("prg/SYS_GimmickLocation"),
  #   dlc02: load_bdat("dlc/SYS_GimmickLocation_dlc02"),
  #   dlc03: load_bdat("dlc/SYS_GimmickLocation_dlc03"),
  #   dlc04: load_bdat("dlc/SYS_GimmickLocation_dlc04"),
  # }

  GMK_LOCATIONS = load_bdat("dlc/SYS_GimmickLocation_dlc04")


  GMK_KIZUNA_EVENTS = {
    "ma40a" => load_bdat("dlc/ma40a_GMK_KizunaEvent")
  }

  MAP_JUMP_LIST = load_bdat "sys/SYS_MapJumpList"

  MAP_LOCATIONS = {}

  MAP_EVENTS = {}

  # MAP_IDS = []

  # MAPS[1].each do |map|
  #   mrsc = MAP_RESOURCES[1].find { |mrsc| mrsc["$id"] == map["ResourceId"] }
  #   MAP_IDS << mrsc["DefaultResource"] unless mrsc.nil? || MAP_IDS.include?(mrsc["DefaultResource"])
  # end

  # MAP_IDS.sort!

  Dir["./data/bf3/bdatjs/**/ma*_GMK_Location*"].each do |path|
    map_id = path.split("/")[-1].split("_GMK_Location")[0]
    MAP_LOCATIONS[map_id] = load_json path
  end

  Dir["./data/bf3/bdatjs/**/ma*_GMK_Event*"].each do |path|
    map_id = path.split("/")[-1].split("_GMK_Event")[0]  
    MAP_EVENTS[map_id] = load_json path
  end

  GIMMICK_TYPES = {
    kizuna_event: "<C403588F>",
    area: "<CF0AA17F>",
    campsite: "<36A5860E>",
  }

  GIMMICK_CATEGORIES = {
    0 => "Campsite",
    1 => "Secret Area",
    2 => "Landmark",
  }

  GIMMICK_TYPES_INV = GIMMICK_TYPES.invert

  Dir["./data/bf3/bdatjs/gb/evt/**/msg_*/*.json"].each do |path|
    msg_evid = path.split("/")[-2]
    evid = msg_evid[4..-1]  
    # next unless evid.start_with?("ev")
    msgs = load_json path
    next if msgs[1].size == 0
    # puts path
    EVENT_MESSAGES[evid] = msgs[1]
  end

  REGIONS = {}
  AREAS = {}
  JUMPABLE_LOCATIONS = {}

  MAP_LOCATIONS.keys.each do |map_id|
    locations = MAP_LOCATIONS[map_id][1]

    gmks = GMK_LOCATIONS[1]
    locations.each do |loc|
      name = LOCATION_NAMES[1].find { |n| n["$id"] == loc["LocationName"] }
      next if name.nil?
    
      jump = MAP_JUMP_LIST[1].find { |j| j["$id"] == loc["MapJumpID"] } if loc["MapJumpID"] != 0
      gmk = GMK_LOCATIONS[1].find { |gmk| gmk["GimmickID"] == if !jump.nil? then jump["FormationID"] else loc["ID"] end }
      gmk = GMK_LOCATIONS[1].find { |gmk| gmk["LocationID"] == loc["ID"] } if gmk.nil?
      next if gmk.nil?

      locat = {
        gmk: gmk,
        location: loc,
        name: name,
      }

      if loc["CategoryPriority"] == 5
        REGIONS[map_id] ||= []
        REGIONS[map_id] << locat
      else
        AREAS[map_id] ||= []
        AREAS[map_id] << locat
      end

      if loc["MapJumpID"] != 0
        JUMPABLE_LOCATIONS[map_id] ||= []
        JUMPABLE_LOCATIONS[map_id] << locat.merge({
          jump: jump,
          type: GIMMICK_CATEGORIES[loc["CategoryPriority"]] || loc["CategoryPriority"]
        })
      end
    end
  end

  def self.find_closest_region loc, map_id
    return nil if REGIONS[map_id].nil?

    nearest_reg = nil
    distance_to_reg = 10000000.0

    REGIONS[map_id].each do |reg|
      # do distance check.

      distance = Math.sqrt((loc["X"] - reg[:gmk]["X"])**2 + (loc["Y"] - reg[:gmk]["Y"])**2 + (loc["Z"] - reg[:gmk]["Z"])**2)
      if distance < distance_to_reg
        distance_to_reg = distance
        nearest_reg = reg
      end
    end

    nearest_reg
  end

  def self.find_closest_area loc, map_id
    return nil if AREAS[map_id].nil?

    nearest_reg = nil
    distance_to_reg = 10000000.0

    #puts "#{loc["X"].round(2)}, #{loc["Y"].round(2)}, #{loc["Z"].round(2)}"

    AREAS[map_id].each do |reg|
      # do distance check.

      distance = Math.sqrt((loc["X"] - reg[:gmk]["X"])**2 + (loc["Y"] - reg[:gmk]["Y"])**2 + (loc["Z"] - reg[:gmk]["Z"])**2)

      #puts distance
    # puts reg[:name]["name"]
    # puts "#{reg[:gmk]["X"].round(2)}, #{reg[:gmk]["Y"].round(2)}, #{reg[:gmk]["Z"].round(2)}" 
      if distance < distance_to_reg
        distance_to_reg = distance
        nearest_reg = reg
      end
    end

    nearest_reg
  end

  def self.find_closest_jump loc, map_id
    return nil if JUMPABLE_LOCATIONS[map_id].nil?

    nearest_reg = nil
    distance_to_reg = 10000000.0

    JUMPABLE_LOCATIONS[map_id].each do |reg|
      # do distance check.
      next if reg[:type] == "Secret Area"

      distance = Math.sqrt((loc["X"] - reg[:gmk]["X"])**2 + (loc["Y"] - reg[:gmk]["Y"])**2 + (loc["Z"] - reg[:gmk]["Z"])**2)
      if distance < distance_to_reg
        distance_to_reg = distance
        nearest_reg = reg
      end
    end

    nearest_reg
  end

  def self.print_location_header loc, map_id
    mrscs = MAP_RESOURCES[1].select { |mrsc| mrsc["DefaultResource"] == map_id }
    xmap = MAPS[1].select { |xmap| mrscs.map { |m| m["$id"] }.include? xmap["ResourceId"] }.find { |xmap| xmap["Name"] != 0 }
    mapname = LOCATION_NAMES[1].find { |n| n["$id"] == xmap["Name"] } unless xmap.nil?

    if !mapname.nil? && !mapname["name"].empty?
      puts "Region: #{mapname["name"]}".colorize(:red)
    else
      puts "Region: #{(REGION_NAMES[map_id] || map_id)}".colorize(:red)
    end

    return if loc["X"] == 0.0 && loc["Y"] == 0.0 && loc["Z"] == 0.0

    area = find_closest_area(loc, map_id)
    region = find_closest_region(loc, map_id)
    jump = find_closest_jump(loc, map_id)

    puts "Area: #{region[:name]["name"]}".colorize(:red) unless region.nil?
    puts "Location: #{area[:name]["name"]}".colorize(:red) unless area.nil?
    puts "Closest Travel Point: #{jump[:name]["name"]} (#{jump[:type]})".colorize(:red) unless jump.nil?
  end

  def self.print_scene_event_theater_header ev
    evid = ev["mstxt"]
    pack = evid2pack(evid)

    # recursively find the parent event. the parent event links to this event via linkID
    root_ev = ev
    counter = 1
    loop do
      next_ev = EVENT_LIST.find { |ev| ev["linkID"] == root_ev["$id"] }
      break if next_ev.nil? || !(next_ev["mstxt"].start_with?("ev") && next_ev["name"].start_with?("ev"))

      scn = EVENT_THEATRE_SCENES[pack][1].find { |scn| scn["ev01_id"] == next_ev["$id"] }
      if !scn.nil?
        root_ev = next_ev
        break
      end

      counter += 1
      root_ev = next_ev
    end

    total = counter
    end_ev = ev
    loop do
      next_ev = EVENT_LIST.find { |ev| ev["$id"] == end_ev["linkID"] }
      break if next_ev.nil? || !(next_ev["mstxt"].start_with?("ev") && next_ev["name"].start_with?("ev"))
      total += 1
      end_ev = next_ev
    end

    scn = EVENT_THEATRE_SCENES[pack][1].find { |scn| scn["ev01_id"] == root_ev["$id"] }
    scn_name = EVENT_SCENE_NAMES[1].find { |n| n["$id"] == scn["title"] } unless scn.nil?
    puts "Chapter: #{ev["chapter"] % 10}".colorize(:red) if ev["chapter"] > 0 && ev["chapter"] < 20
    puts "Scene: “#{scn_name["name"]}” (Part #{counter}/#{total})".colorize(:red) unless scn_name.nil?
  end
end