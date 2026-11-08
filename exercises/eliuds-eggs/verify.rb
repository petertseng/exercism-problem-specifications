require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'eggCount') { |i, _|
  Integer(i['number']).to_s(2).count(?1)
}
