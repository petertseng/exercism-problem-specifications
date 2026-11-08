require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

fs = {
  'fn(x) -> true' => ->_ { true },
  'fn(x) -> false' => ->_ { false },
  'fn(x) -> x % 2 == 1' => :odd?,
  'fn(x) -> x % 2 == 0' => :even?,
  "fn(x) -> starts_with(x, 'z')" => ->s { s.start_with?(?z) },
  'fn(x) -> contains(x, 5)' => ->s { s.include?(5) },
}.freeze

props = {
  'keep' => :select,
  'discard' => :reject,
}.freeze

cases = by_property(json['cases'], props.keys)

cases.each { |prop, cs|
  verify(cs, property: prop) { |i, _|
    i['list'].public_send(props.fetch(prop), &fs.fetch(i['predicate']))
  }
}
