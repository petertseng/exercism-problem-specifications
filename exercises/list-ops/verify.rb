require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

fs = {
  '(x) -> x modulo 2 == 1' => :odd?,
  '(x) -> x + 1' => :succ,
  '(x, y) -> x * y' => :*,
  '(x, y) -> x + y' => :+,
  '(x, y) -> x / y' => :/,
}.freeze

props = {
  'append' => ->(c) { c['list1'] + c['list2'] },
  'concat' => ->(c) { c['lists'].flatten(1) },
  'filter' => ->(c) { c['list'].select(&fs.fetch(c['function'])) },
  'length' => ->(c) { c['list'].size },
  'map' => ->(c) { c['list'].map(&fs.fetch(c['function'])) },
  'foldl' => ->(c) { c['list'].reduce(c['initial'], &fs.fetch(c['function'])) },
  'foldr' => ->(c) { c['list'].reverse.reduce(c['initial']) { |x, y| fs.fetch(c['function']).to_proc[y, x] } },
  'reverse' => ->(c) { c['list'].reverse },
}.freeze

if json['cases'].size != props.size
  keys = props.keys
  [json['cases'].size, props.size].max.times { |n|
    puts '%12s / %12s' % [json.dig('cases', n, 'cases', 0, 'property'), keys[n]]
  }
  raise 'Length mismatch'
end

json['cases'].zip(props) { |cs, (prop, f)|
  verify(cs['cases'], property: prop) { |i, _| f[i] }
}
