require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

cases = json['cases'].flat_map { |c|
  c.has_key?('cases') ? c['cases'] : c
}

cases = by_property(cases, %w(modifier ability character strength))

# Not really interested in testing the other properties
verify(cases['modifier'], property: 'modifier') { |i, _|
  (i['score'] - 10) / 2
}
