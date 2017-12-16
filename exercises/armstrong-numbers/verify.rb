require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'isArmstrongNumber') { |i, _|
  (ds = (n = i['number']).digits).sum { |d| d ** ds.size } == n
}
