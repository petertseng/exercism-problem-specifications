require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

cases = by_property(json['cases'], %w(row column))

verify(cases['row'], property: 'row') { |i, _|
  i['string'].each_line.map { |l| l.split.map(&:to_i) }[i['index'] - 1]
}

verify(cases['column'], property: 'column') { |i, _|
  i['string'].each_line.map { |l| l.split.map(&:to_i) }.transpose[i['index'] - 1]
}
