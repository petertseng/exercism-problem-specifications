require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'].each { |c| c['expected'].sort_by! { |e| e.values_at('row', 'column') } }, property: 'saddlePoints') { |i, _|
  rows = i['matrix']
  row_maxes = rows.map(&:max)
  col_mins = rows.transpose.map(&:min)
  rows.flat_map.with_index { |row, y|
    row.each_with_index.select { |n, x|
      n == row_maxes[y] && n == col_mins[x]
    }.map { |_, x| {
      'row' => y + 1,
      'column' => x + 1,
    }.freeze }
  }.sort_by { |e| e.values_at('row', 'column') }.freeze
}
