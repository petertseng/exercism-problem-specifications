require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

class NotFound < StandardError; end

verify(json['cases'], error_class: NotFound, property: 'find') { |i, _|
  i['array'].index(i['value']) or raise NotFound, 'not in the array'
}
