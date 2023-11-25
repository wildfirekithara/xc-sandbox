# very bruteforcey search for name/hash in directory of wwise bnk & wem

require "./fnvhash32.rb"

def wwise_scan_dir dir, str
  relpath = ->(path) { path.sub(dir, "") }

  if str.start_with?(":")
    ha = str[1..-1].to_i
  else
    ha = fnvhash32 str
  end

  hashpack = [ha].pack("V").force_encoding("ASCII-8BIT")

  # puts "Scanning bnks data:"
  Dir["#{dir}/**/*.bnk"].each do |bnk|  
  puts relpath[bnk] if File.basename(bnk) == ha.to_s + ".bnk"

  bnk_str = File.read(bnk).force_encoding("ASCII-8BIT")
    if bnk_str.include?(hashpack)
      index = bnk_str.index(hashpack)
      puts "#{relpath[bnk]} #{ha} found @ 0x%X" % index
    end
  end

  # puts "Scanning wem names:"
  Dir["#{dir}/**/*.wem"].each do |wem|
    puts relpath[wem] if File.basename(wem) == ha.to_s + ".wem"
  end  
end

if __FILE__ == $0
  wwise_scan_dir ARGV[0], ARGV[1]
end
