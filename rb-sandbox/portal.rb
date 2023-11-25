# modify portals

require "./scripts/bf3.rb"

FTP_HOST = "192.168.0.171"
FTP_PORT = 5000

FORNIS_PORTALS = BF3::load_bdat "dlc/ma04a_GMK_JumpPortal"
CHALLENGE_PORTALS = BF3::load_bdat "dlc/ma25a_GMK_JumpPortal"
CENTOMNIA_PORTALS = BF3::load_bdat "dlc/ma40a_GMK_JumpPortal"
OLD_ORIGIN_PORTALS = BF3::load_bdat "dlc/ma44a_GMK_JumpPortal"
MA40A_LOCATIONS = BF3::MAP_LOCATIONS["ma40a"]
GENERIC_WINDOW_MS = BF3::load_bdat "gb/game/menu/msg_mnu_GENERIC_WINDOW_MS"

def save
  BF3::write_bdat FORNIS_PORTALS
  BF3::write_bdat CENTOMNIA_PORTALS
  BF3::write_bdat GENERIC_WINDOW_MS
  BF3::write_bdat MA40A_LOCATIONS

  BF3::pack_bdats

  # ask user if they wanna copy to atmosphere

  BF3::print_file_list

  puts "Copy to Atmosphere? (y/n)"
  BF3::send_bdats_to_emulator_atmosphere if gets.chomp.downcase == "y"

  puts "Upload to Switch? (y/n)"
  BF3::ftp_upload_to_switch_atmosphere FTP_HOST, FTP_PORT if gets.chomp.downcase == "y"
end

ARGS = ARGV.dup
ARGV.clear

if ARGS[0] == "--reset"
  puts "Resetting data…"

  save
  exit 1
end


def rewire_portal portal, replacement_portal: nil, replace_props: false, map_jump_id: nil
  portal["MapJumpID"] = map_jump_id || replacement_portal["MapJumpID"]
  portal["DisableAccess"] = 0

  return unless replace_props

  portal["Condition"] = replacement_portal["Condition"]
  portal["IconType"] = replacement_portal["IconType"]
  portal["IconOffset"] = replacement_portal["IconOffset"]
  portal["AccessRange"] = replacement_portal["AccessRange"]
  portal["Name"] = replacement_portal["Name"]
  portal["<3EA4AF95>"] = replacement_portal["<3EA4AF95>"]
  portal["<89FCCF2A>"] = replacement_portal["<89FCCF2A>"]
  portal["<6DF8EE99>"] = replacement_portal["<6DF8EE99>"]
end


to_challenge_portal = FORNIS_PORTALS[1].first
to_fornis_portal = CHALLENGE_PORTALS[1].first
to_origin_portal = CENTOMNIA_PORTALS[1].first
to_centomnia_portal = OLD_ORIGIN_PORTALS[1].first

MA40A_LOCATIONS[1].select { |loc| loc["<D8EB49D8>"] == 14733 }.each do |loc|
  loc["<D8EB49D8>"] = 0
end

rewire_portal to_challenge_portal, map_jump_id: 1565

# rewire_portal to_challenge_portal, to_centomnia_portal, true
# rewire_portal to_origin_portal, to_fornis_portal

centomnia_text = GENERIC_WINDOW_MS[1].find { |msg| msg["$id"] == 112 }
centomnia_text["name"] = "Time travel back to the Vermilion Woods in the past?"

# fornis_text = GENERIC_WINDOW_MS[1].find { |msg| msg["$id"] == 113 }
# fornis_text["name"] = "Time travel forward to the Fornis Region in the future?"

BF3::write_bdat FORNIS_PORTALS
BF3::write_bdat CENTOMNIA_PORTALS
BF3::write_bdat GENERIC_WINDOW_MS
BF3::write_bdat MA40A_LOCATIONS

BF3::pack_bdats

# ask user if they wanna copy to atmosphere

BF3::print_file_list

puts "Copy to Atmosphere? (y/n)"
BF3::send_bdats_to_emulator_atmosphere if gets.chomp.downcase == "y"

puts "Upload to Switch? (y/n)"
BF3::ftp_upload_to_switch_atmosphere FTP_HOST, FTP_PORT if gets.chomp.downcase == "y"

save