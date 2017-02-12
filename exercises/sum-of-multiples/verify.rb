require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'sum') { |i, _|
  factors = i['factors'].reject(&:zero?)
  limit = i['limit']
  (1...limit).select { |n|
    factors.any? { |f| n % f == 0 }
  }.sum
}
