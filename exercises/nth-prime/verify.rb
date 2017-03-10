require 'json'
require 'prime'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'prime') { |i, _|
  Prime.first(i['number']).last or raise 'no'
}
