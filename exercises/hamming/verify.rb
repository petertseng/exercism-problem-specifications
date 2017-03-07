require 'json'
require_relative '../../verify'

def hamming_dist(s1, s2)
  raise ArgumentError, "argument lengths must be equal, but #{s1.size} != #{s2.size}" unless s1.size == s2.size
  s1.each_char.zip(s2.each_char).count { |c1, c2| c1 != c2 }
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'distance') { |i, _|
  hamming_dist(i['strand1'], i['strand2'])
}
