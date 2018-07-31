require 'json'
require_relative '../../verify'

cases = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))['cases']

raise "There should be exactly two cases, not #{cases.size}" if cases.size != 2

def alphabets(key)
  normal = (?a..?z).to_a.map(&:freeze).freeze
  a, b = key.values_at(?a, ?b)
  raise 'not coprime' if a.gcd(normal.size) != 1
  [normal.join, normal.each_index.map { |i| normal[(i * a + b) % normal.size] }.join]
end

verify(cases[0]['cases'], property: 'encode') { |i, _|
  i['phrase'].tr('., ', '').downcase.tr(*alphabets(i['key'])).each_char.each_slice(5).map(&:join).join(' ')
}

verify(cases[1]['cases'], property: 'decode') { |i, _|
  i['phrase'].delete(' ').tr(*alphabets(i['key']).reverse)
}
