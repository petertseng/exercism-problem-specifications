require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'leapYear') { |i, _|
  div_by = ->(n) { i['year'] % n == 0 }
  div_by[4] && !div_by[100] || div_by[400]
}
