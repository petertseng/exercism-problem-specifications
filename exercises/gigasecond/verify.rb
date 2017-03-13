require 'json'
require 'time'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

cases = by_property(json['cases'], %w(add isEqual))

verify(cases['add'], property: 'add') { |i, _|
  bd = i['moment']
  t = bd + "#{'T00:00:00' unless bd.include?(?T)} UTC"
  (Time.strptime(t, '%FT%T %Z') + 1e9).to_s.split.take(2).join(?T)
}

verify(cases['isEqual'], property: 'isEqual') { |i, _|
  'moment === moment'
}
