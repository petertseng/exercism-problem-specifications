require 'json'
require_relative '../../verify'

EARTH = 31557600.0

# Wow, this verifies the description too!
orbits = File.readlines(File.join(__dir__, 'instructions.md')).grep(/^\| [A-Z][a-z]* +\| \d/).to_h { |l|
  _, name, period = l.split(?|)
  [name.strip.freeze, Float(period) * EARTH]
}.merge('Earth' => EARTH).freeze

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

DELTA = 0.005
verify(json['cases'], accept: ->(c, ans) { (ans - c['expected']).abs < DELTA }, property: 'age') { |i, _|
  i['seconds'] / orbits.fetch(i['planet'])
}
