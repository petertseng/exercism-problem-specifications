require 'json'
require_relative '../../verify'

COLOURS = %w(black brown red orange yellow green blue violet grey white).map(&:freeze).freeze

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'][0]['cases'], property: 'colorCode') { |i, _|
  COLOURS.index(i['color'])
}

verify([json['cases'][1]], property: 'colors') { COLOURS }
