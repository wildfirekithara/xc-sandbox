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
