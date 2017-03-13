require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], error: ->(c) { c['expected'].nil? }, property: 'decimal') { |i, _|
  Integer(i['binary'], 2)
}
