require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'calculateFrequencies') { |i, _|
  i['texts'].join.split.join.downcase.gsub(/[[:punct:]]|\d/, '').chars.tally
}
