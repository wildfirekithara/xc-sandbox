# hastily parse SND section of .aab files to grab event names
# timed to .anm files
# --scan to scan for event names in wwise bnk & wem files

require "murmurhash3"
require "./wwise-search.rb"

#fn = File.expand_path("~/code/ntw/fcam/data/bf3/aoc4/chr/ch/ch41141000_wp44_talent00.aab")

fn = ARGV[0]
should_scan = ARGV[1] == "--scan"

bin = File.read(fn).force_encoding("ASCII-8BIT")

header = bin[4, 4]
raise "Expected EFT" if header != "EFT "

sndstart = bin.index("SND ")
raise "No SND section found" if sndstart.nil?

sndcount = bin[sndstart + 8, 4].unpack("V")[0]

puts "SND count: #{sndcount}"
puts "-----"
i = sndstart + 0xC
names = []

sndcount.times do |sndi|

  event_hash = bin[i, 4].unpack("V")[0]

  i += 0x4
  i += 0x24

  sndname = bin[i, 0x40].split("\0").first
  print "SND #{sndi} -- 0x%X -- #{sndname}" % event_hash
  i += 0x40

  f1 = bin[i, 4].unpack("f")[0]
  print " -- Time #{f1}s"
  i += 0x4
  u32 = bin[i, 4].unpack("V")[0]
  if u32 != 0x20
    puts "expected 0x20, got #{u32} -- at 0x%X" % i
    exit(1)
  end
  
  i += 0x50
  u16 = bin[i, 2].unpack("v")[0]
  if u16 != 0xFFFF
    puts "expected 0xFFFF, got #{u16} -- at 0x%X" % i
    exit(1)
  end
  i += 0x2
  i += 0xE
  u16 = bin[i, 2].unpack("v")[0]
  if u16 != 0x6
    puts "expected 0x6, got #{u16} -- at 0x%X" % i
    exit(1)
  end
  i += 0x2

  name2 = bin[i, 0x40].split("\0").first
  print " -- #{name2}"
  i += 0x40
  i += 0x2

  event_name = bin[i, 0x40].split("\0").first
  puts " -- Event: #{event_name}"
  i += 0x40
  i += 0xD0

  names << event_name

  wwise_scan_dir File.expand_path("~/code/ntw/fcam/tools/pck"), event_name if should_scan

  # event_hash_name = "evt:/#{event_name}"
  # mur_event_hash = MurmurHash3::V32.str_digest(event_hash_name).unpack("V")[0]
  # fnv_event_hash = fnvhash32(event_hash_name)
  # if mur_event_hash != event_hash
  #   puts "Event hash mismatch: 0x%X != 0x%X" % [mur_event_hash, event_hash]
  # end
  # if fnv_event_hash != event_hash
  #   puts "Event hash mismatch: 0x%X != 0x%X" % [fnv_event_hash, event_hash]
  # end
end

puts names