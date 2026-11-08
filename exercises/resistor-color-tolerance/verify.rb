require 'json'
require_relative '../../verify'

COLOURS = %w(black brown red orange yellow green blue violet grey white).map(&:freeze).freeze
TOL = {
  'grey' => 0.05,
  'violet' => 0.1,
  'blue' => 0.25,
  'green' => 0.5,
  'brown' => 1,
  'red' => 2,
  'gold' => 5,
  'silver' => 10,
}

not_reimplemented = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))['cases'].reject { |c| c['uuid'] == 'c001757b-d388-4f42-9987-23e42bc22d68' }

si = {
  giga: 1_000_000_000,
  mega: 1_000_000,
  kilo: 1_000,
}.freeze

verify(not_reimplemented, property: 'labelDecoder') { |i, _|
  next {'value' => 0, 'unit' => 'ohms'} if i['colors'] == ['black']

  v = i['colors'][..-3].reduce(0) { |acc, colour|
    acc * 10 + COLOURS.index(colour)
  } * 10 ** COLOURS.index(i['colors'][-2])
  prefix, div = si.find { |_, vv| v >= vv } || ['', 1]
  {
    'value' => Rational(v, div),
    'unit' => "#{prefix}ohms",
    'tolerance' => "±#{TOL.fetch(i['colors'][-1])}%",
  }
}
