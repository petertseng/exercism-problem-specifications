require 'json'
require 'prime'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'factors') { |i, _|
  Prime.prime_division(i['value']).flat_map { |f, n| [f] * n }
}
