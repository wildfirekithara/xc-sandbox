# hastily parse SND section of .aab files to grab event names
# these are usually paired with/timed to .anm files
# --input <aab file | dir of aab files> to parse
# --scan <dir> to scan for event names in wwise bnk & wem files
# --midi <dir> to output midi files for each file with event timeline

USAGE = <<EOF

Usage: ruby aab_parse.rb --input <FILE | DIR> [--scan <WWISE_DIR>] [--midi <MIDI_DIR>]

--input <FILE | DIR> - .aab file or directory of .aab files to parse. Directories will be scanned recursively.
--scan <WWISE_DIR> - Directory of wwise .bnk & .wem files to scan for event names
--midi <MIDI_DIR> - Directory to output .mid files for each file with event timeline
EOF

require "./wwise-search.rb"
require 'optparse'
require 'fileutils'

# big endian
# msb is set if there are more bytes to read
def midi_var_len_pack(val)
  val = val.to_i
  bytes = []
  loop do
    bytes << (val & 0x7F)
    val >>= 7
    break if val == 0
  end
  bytes = bytes.reverse.map.with_index do |b, i|
    b |= 0x80 if i < bytes.length - 1
    b
  end
  bytes.pack("C*")
end

def u24_pack_be(val)
  bytes = [val.to_i].pack("N")[1..-1]
end

options = {}
OptionParser.new do |opt|
  opt.on('-i', '--input <FILE | DIR>') { |o| options[:input] = o }
  opt.on('-s', '--scan <WWISE_DIR>') { |o| options[:scan] = o }
  opt.on('-m', '--midi <MIDI_DIR') { |o| options[:midi] = o }
  opt.on('-h', '--help') { puts USAGE; exit }
end.parse!

if options[:input].nil?
  puts "Missing input file or directory"
  puts USAGE
  exit 1
end

#fn = File.expand_path("~/code/ntw/fcam/data/bf3/aoc4/chr/ch/ch41141000_wp44_talent00.aab")

input = options[:input]
scan_dir = options[:scan]
midi_dir = options[:midi]

names = []

if input.end_with?(".aab")
  files = [input]
else
  files = Dir["#{input}/**/*.aab"]
end

files.each do |fn|
  bin = File.read(fn).force_encoding("ASCII-8BIT")

  aab_name = File.basename(fn, ".aab")

  i = 4

  header = bin[i, 4]
  if header != "EFT "
    puts "skipping #{fn} - Invalid .aab, expected EFT header" if header != "EFT "
    next
  end

  i += 4

  sections = 0

  loop do
    sndstart = bin[i..-1].index("SND ")
    if sndstart.nil?
      puts "skipping #{fn} - No SND sections found" if sections == 0
      break
    end
    sections += 1

    i += sndstart
    i += 0x4
    i += 0x4

    sndcount = bin[i, 4].unpack("V")[0]

    puts fn
    puts "SND count: #{sndcount}"
    i += 0x4

    events_timeline = []
    sndcount.times do |sndi|


      event_hash = bin[i, 4].unpack("V")[0]

      i += 0x4
      i += 0x24

      sndname = bin[i, 0x40].split("\0").first
      print "SND #{sndi} -- 0x%X -- #{sndname}" % event_hash
      i += 0x40

      ts = bin[i, 4].unpack("f")[0]
      print " -- Time #{ts}"
      i += 0x4
      u32 = bin[i, 4].unpack("V")[0]
      # if u32 != 0x20
      #   puts "expected 0x20, got #{u32} -- at 0x%X" % i
      #   break
      # end
      
      i += 0x50
      u16 = bin[i, 2].unpack("v")[0]
      if u16 != 0xFFFF
        puts "expected 0xFFFF, got #{u16} -- at 0x%X" % i
        break
      end
      i += 0x2
      i += 0xE
      u16 = bin[i, 2].unpack("v")[0]
      if u16 != 0x6
        puts "expected 0x6, got #{u16} -- at 0x%X" % i
        break
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
      events_timeline << [ts, event_name, sndi]
      wwise_scan_dir scan_dir, event_name if scan_dir
    end

    if midi_dir
      FileUtils.mkdir_p(midi_dir) unless File.exist?(midi_dir)
      midi_name = "#{aab_name}_#{sections}"
      midi_fn = File.join(midi_dir, midi_name + ".mid")
      File.open(midi_fn, "w") do |f|
        ppqn = 480
        fps = 30.0
        tempo = 150.0

        f.write "MThd"
        f.write [6].pack("N") # header size
        f.write [0].pack("n") # format 0
        f.write [1].pack("n") # 1 track
        f.write [ppqn].pack("n")

        f.write "MTrk"
        track_size_pos = f.tell
        f.write [0].pack("N") # track size placeholder

        f.write midi_var_len_pack(0)
        f.write [0xFF, 0x51, 0x03].pack("C*") # tempo meta-event
        micros_per_qn = 60_000_000.0 / tempo
        f.write u24_pack_be(micros_per_qn)

        micros_per_frame = 1_000_000.0 / fps
        ticks_per_frame = (micros_per_frame / micros_per_qn) * ppqn

        base_note = 0x3C
        last_note = nil
        last_ts = 0

        events_timeline.sort_by { |e| e[0] }.each do |(ts, _, sndi)|
          delta_ticks = (ts - last_ts) * ticks_per_frame
          note = base_note + sndi
          f.write midi_var_len_pack(delta_ticks)
          if last_note
            f.write [0x80, last_note, 0x7F].pack("C*")
            f.write midi_var_len_pack(0)
          end
          f.write [0x90, note, 0x7F].pack("C*")
          last_note = note
          last_ts = ts
        end

        f.write midi_var_len_pack(480)
        if last_note
          f.write [0x80, last_note, 0x7F].pack("C*")
          f.write midi_var_len_pack(0)
        end
        f.write [0xFF, 0x2F, 0x00].pack("C*")

        track_size = f.tell - track_size_pos - 4
        f.seek track_size_pos
        f.write [track_size].pack("N")
      end
    end
  end

end
puts names.compact.uniq.sort
