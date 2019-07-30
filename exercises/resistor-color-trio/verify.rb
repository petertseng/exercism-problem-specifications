require 'json'
require_relative '../../verify'

COLOURS = %w(black brown red orange yellow green blue violet grey white).map(&:freeze).freeze

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

si = {
  giga: 1_000_000_000,
  mega: 1_000_000,
  kilo: 1_000,
}.freeze

verify(json['cases'], property: 'label') { |i, _|
  v = i['colors'].take(2).reduce(0) { |acc, colour|
    acc * 10 + COLOURS.index(colour)
  } * 10 ** COLOURS.index(i['colors'][2])
  prefix, div = si.find { |_, vv| v >= vv } || ['', 1]
  {
    'value' => Rational(v, div),
    'unit' => "#{prefix}ohms",
  }
}
