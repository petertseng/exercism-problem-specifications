require 'json'
require_relative '../../verify'

EARTH = 31557600.0

# Wow, this verifies the description too!
orbits = File.readlines(File.join(__dir__, 'description.md')).grep(/orbital period/).to_h { |l|
  planet = l.split.find { |w| w.include?(?:) }[0...-1]
  period = l[/\d+\.\d+/].to_f * EARTH
  [planet, period]
}.merge('Earth' => EARTH).freeze

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

DELTA = 0.01
verify(json['cases'], accept: ->(c, ans) { (ans - c['expected']).abs < DELTA }, property: 'age') { |i, _|
  i['seconds'] / orbits[i['planet']]
}
