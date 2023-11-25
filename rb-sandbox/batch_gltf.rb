# batch convert wimdo to gltf
require 'fileutils'

model_dir = File.expand_path("~/code/ntw/fcam/data/bf3/aoc4/chr/oj")
gltf_output_dir = File.expand_path("~/code/ntw/fcam/data/bf3/extract/gltf_oj_dlc04")
shader_json_path = File.expand_path("~/code/ntw/fcam/data/bf3/xc3.json")

FileUtils.mkdir_p(gltf_output_dir)
pwd = Dir.pwd
Dir.chdir(File.expand_path("~/code/ntw/fcam/tools/xc3_lib"))

Dir.glob("#{model_dir}/*.wimdo").each do |oj_path|
  output_gltf = File.join(gltf_output_dir, File.basename(oj_path, ".wimdo") + ".gltf")
  puts "Converting #{oj_path} to #{output_gltf}"
  `cargo run -p xc3_gltf #{oj_path} #{output_gltf} #{shader_json_path}`
end
