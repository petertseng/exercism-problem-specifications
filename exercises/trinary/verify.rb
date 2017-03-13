require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

# This is a ridiculous error condition, but the exercise is deprecated so who cares?
verify(json['cases'].flat_map { |c| c['cases'] }, error: ->(c) { c['expected'] == 0 }, property: 'toDecimal') { |i, _|
  Integer(i['trinary'].to_s, 3)
}
