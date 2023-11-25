# assorted helpers for hashing, bdat hexdigest string format

require 'murmurhash3'

def mhash str
  mur = MurmurHash3::V32.str_hexdigest(str, 0).upcase
  # reverse bytes
  mur = mur.scan(/../).reverse.join
  mur
end

def fmt_mhash str
  "<#{mhash(str)}>"
end

if __FILE__ == $0
  puts fmt_mhash ARGV[0]
end
