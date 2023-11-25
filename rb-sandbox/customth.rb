# custom theatre events

require "./scripts/bf3.rb"
require "./scripts/hash.rb"

FTP_HOST = "192.168.0.171"
FTP_PORT = 5000

def add_new list, obj, id=nil
  next_id = id || (list.map { |obj| obj["$id"] }.max + 1)
  new_obj = obj.merge({ "$id" => next_id })
  list << new_obj
  new_obj  
end

scenes = BF3::EVENT_THEATRE_SCENES[:dlc04]
events = BF3::EVENT_LISTS.find { |el| el[:pack] == :dlc04 }[:data]
scene_names = BF3::EVENT_SCENE_NAMES

name = scene_names[1].find { |name| name["name"] == "Struggle" }
scene = scenes[1].find { |scene| scene["title"] == name["$id"] }
scene_index = scenes[1].index(scene)

# new_name = add_new scene_names[1], name.merge({ "name" => "Glimmer vs Nikol" })
# new_scene = add_new scenes[1], scene.merge({
#   "ID" => fmt_mhash("custom_scene1"),
#   "title" => new_name["$id"],
#   "sort_index" => scene["sort_index"] + 1,
#   "ev01_id" => 14020,
# })

new_name = add_new scene_names[1], name.merge({ "name" => "Why the spark not?!" })
new_scene = add_new scenes[1], scene.merge({
  "ID" => fmt_mhash("custom_scene1"),
  "title" => new_name["$id"],
  "sort_index" => scene["sort_index"] + 1,
  "ev01_id" => 17747,
})

# new_name = add_new scene_names[1], name.merge({ "name" => "The Future" })
# new_scene = add_new scenes[1], scene.merge({
#   "ID" => fmt_mhash("custom_scene2"),
#   "title" => new_name["$id"],
#   "sort_index" => scene["sort_index"] + 1,
#   "fixed_time" => 4,
#   "fixed_weather" => 0,
#   "<FCEC2838>" => 3,
#   "ev01_id" => 10032,
#   "picid" => 15,
# })

# reorder scenes by scn_group and sort_index
scenes[1].sort_by! { |scene| [scene["scn_group"], scene["sort_index"]] }

# renumber scene $id
id = 399
scenes[1].each_with_index do |scene, i|
  id += 1
  scene["$id"] = id
end

BF3::write_bdat scene_names
BF3::write_bdat scenes

BF3::pack_bdats

BF3::print_file_list
puts "Copy to Atmosphere? (y/n)"
BF3::send_bdats_to_emulator_atmosphere if gets.chomp.downcase == "y"
puts "Upload to Switch? (y/n)"
BF3::ftp_upload_to_switch_atmosphere FTP_HOST, FTP_PORT if gets.chomp.downcase == "y"

