require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'squareRoot') { |i, _|
  Math.sqrt(i['radicand']).to_i
}
