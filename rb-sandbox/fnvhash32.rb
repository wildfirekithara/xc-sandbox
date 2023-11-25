# FNV-1a 32bit hash with defaults for WWise 32-bit hashes

FNV_PRIME32 = 16777619
FNV_OFFSET32 = 2166136261
FNV_BITS32 = 32

def fnvhash32 str
  str = str.downcase

  hval = FNV_OFFSET32
  str.each_byte do |b|
    hval *= FNV_PRIME32
    hval &= 0xffffffff
    hval ^= b
    hval &= 0xffffffff
  end

  return hval if hval < 2**(FNV_BITS32-1)
  # xor fold
  mask = 2**FNV_BITS32 - 1
  hval = (hval & mask) ^ (hval >> FNV_BITS32)
  hval & 0xffffffff
end

if __FILE__ == $0
  ha = fnvhash32 ARGV[0]
  puts ha
  puts "%08X" % ha
  puts ("%08X" % [ha].pack("L").unpack("N").first).split("").each_slice(2).map(&:join).join(" ")
end
