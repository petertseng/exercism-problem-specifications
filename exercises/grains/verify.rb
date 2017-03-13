require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

raise "There should be exactly two cases, not #{json['cases'].size}" if json['cases'].size != 2

verify(json['cases'][0]['cases'], property: 'square') { |i, _|
  sq = i['square']
  raise "no #{i}" if sq <= 0 || sq > 64
  2 ** (sq - 1)
}

verify([json['cases'][1]], property: 'total') {
  2 ** 64 - 1
}
