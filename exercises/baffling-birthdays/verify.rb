require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

raise "There should be exactly two cases, not #{json['cases'].size}" if json['cases'].size != 3

verify(json['cases'][0]['cases'], property: 'sharedBirthday') { |i, _|
  bds = i['birthdates']
  bds.size != bds.uniq { |bd| bd.split('-')[1..] }.size
}

verify(json['cases'][1]['cases'], accept: ->(_, _) { true }, property: 'randomBirthdates') { }

DELTA = 0.000001
verify(json['cases'][2]['cases'], accept: ->(c, ans) { (ans - c['expected']).abs < DELTA }, property: 'estimatedProbabilityOfSharedBirthday') { |i, _|
  (1.0 - i['groupSize'].times.reduce(1) { |p, j| p * Rational(365 - j, 365) }) * 100
}
