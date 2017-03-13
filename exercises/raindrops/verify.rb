require 'json'
require_relative '../../verify'

DROPS = {
  Pling: 3,
  Plang: 5,
  Plong: 7,
}.freeze

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'convert') { |i, _|
  n = i['number']
  DROPS.reduce(nil) { |acc, (text, factor)|
    n % factor == 0 ? "#{acc}#{text}" : acc
  } || n.to_s
}
