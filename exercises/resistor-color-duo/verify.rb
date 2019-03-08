require 'json'
require_relative '../../verify'

COLOURS = %w(black brown red orange yellow green blue violet grey white).map(&:freeze).freeze

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'value') { |i, _|
  i['colors'].take(2).reduce(0) { |acc, colour|
    acc * 10 + COLOURS.index(colour)
  }
}
