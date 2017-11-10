require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

CODONS = File.readlines(File.join(__dir__, 'description.md')).select { |l|
  l.include?(?|) && l.match?(/[ACGU]{3}/)
}.flat_map { |l|
  ks, v = l.split(?|)
  v.strip!
  v.freeze
  ks.split(?,).map(&:strip).map { |k| [k, v] }
}.to_h.freeze

verify(json['cases'], property: 'proteins') { |i, _|
  i['strand'].each_char.each_slice(3).map(&:join).map(&CODONS).take_while { |a| a != 'STOP' }
}
