require 'json'
require 'time'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'add') { |i, _|
  bd = i['moment']
  t = bd + "#{'T00:00:00' unless bd.include?(?T)} UTC"
  (Time.strptime(t, '%FT%T %Z') + 1e9).to_s.split.take(2).join(?T)
}
