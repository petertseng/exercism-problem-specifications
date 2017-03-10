require 'json'
require_relative '../../verify'

must_be_pipe = ->c { raise "got #{c} instead of |" if c != ?| }

# Wow, this verifies the description too!
scores = File.readlines(File.join(__dir__, 'instructions.md')).grep(/^\| [A-Z](, [A-Z])* *\| *\d+ *\|$/).flat_map { |line|
  letters = line.tr(?,, '').split
  letters.shift.then(&must_be_pipe)
  letters.pop.then(&must_be_pipe)
  score = Integer(letters.pop)
  letters.pop.then(&must_be_pipe)
  letters.flat_map { |l| [[l.upcase, score], [l.downcase, score]] }
}.to_h.freeze

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'score') { |i, _|
  i['word'].each_char.sum(&scores)
}
