require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'toRna') { |i, _|
  raise 'no' unless /^[ACGT]*$/.match?(i['dna'])
  i['dna'].tr('ACGT', 'UGCA')
}
