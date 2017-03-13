require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'rebase') { |i, _|
  base = i['inputBase']
  raise "no base #{base}" if base < 2
  i['digits'].reduce(0) { |a, e|
    raise "nope, #{e} negative" if e < 0
    raise "nope, #{e} too big" if e >= base
    a * base + e
  }.digits(i['outputBase']).reverse
}
