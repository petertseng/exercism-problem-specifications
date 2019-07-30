require 'json'
require_relative '../../verify'

COLOURS = %w(black brown red orange yellow green blue violet grey white).map(&:freeze).freeze

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'label') { |i, _|
  v = i['colors'].take(2).reduce(0) { |acc, colour|
    acc * 10 + COLOURS.index(colour)
  } * 10 ** COLOURS.index(i['colors'][-1])
  {
    'value' => Rational(v, v >= 1000 ? 1000 : 1),
    'unit' => "#{'kilo' if v >= 1000}ohms",
  }
}
