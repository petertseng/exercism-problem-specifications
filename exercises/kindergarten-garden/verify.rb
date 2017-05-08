require 'json'
require_relative '../../verify'

KID_NAMES = %w(Alice Bob Charlie David Eve Fred Ginny Harriet Ileana Joseph Kincaid Larry).map(&:freeze).freeze
PLANTS = {
  ?C => 'clover',
  ?G => 'grass',
  ?R => 'radishes',
  ?V => 'violets',
}.each_value(&:freeze).freeze
PLANTS_PER_ROW_PER_KID = 2

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

cases = json['cases'].flat_map { |c| c['cases'].flat_map { |cc| cc['cases'] || cc } }

verify(cases, property: 'plants') { |i, _|
  rows = i['diagram'].split.map { |row|
    row.each_char.each_slice(PLANTS_PER_ROW_PER_KID)
  }
  plant_groups = rows[0].zip(*rows[1..-1]).map { |group_rows|
    group_rows.flatten.map(&PLANTS).freeze
  }

  plant_groups[KID_NAMES.index(i['student'])]
}
