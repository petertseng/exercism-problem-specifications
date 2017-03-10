require 'json'
require_relative '../../verify'

# Wow, this verifies the description too!
scores = File.readlines(File.join(__dir__, 'description.md')).grep(/^[A-Z](, [A-Z])* +\d+$/).flat_map { |line|
  letters = line.tr(?,, '').split
  score = letters.pop.to_i
  letters.flat_map { |l| [[l.upcase, score], [l.downcase, score]] }
}.to_h.freeze

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'score') { |i, _|
  i['word'].each_char.sum(&scores)
}
