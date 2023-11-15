require 'fileutils'

JOBS = [{
  src: File.expand_path("~/code/ntw/fcam/data/bf3/aoc4/menu/image"),
  dest: File.expand_path("~/code/ntw/fcam/data/bf3/extract/aoc4_menu"),
}, {
  src: File.expand_path("~/code/ntw/fcam/data/bf3/romfs/menu/image"),
  dest: File.expand_path("~/code/ntw/fcam/data/bf3/extract/romfs_menu"),
}]

JOBS.each do |job|
  src, dest = job.values_at(:src, :dest)
  FileUtils.mkdir_p(dest)
  Dir.glob("#{src}/**/*.wilay").each do |wilay_path|
    output_path = wilay_path.sub(src, dest)
    FileUtils.mkdir_p(File.dirname(output_path))
    output_png = output_path.sub(".wilay", ".png")

    puts "Converting #{wilay_path} to #{output_png}"
    `xc3_tex #{wilay_path} #{output_png}`
    break
  end
end
