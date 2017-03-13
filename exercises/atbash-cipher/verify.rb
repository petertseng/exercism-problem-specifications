require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

raise "There should be exactly two cases, not #{json['cases'].size}" if json['cases'].size != 2

alphabet = 'abcdefghijklmnopqrstuvwxyz'.freeze

verify(json['cases'][0]['cases'], property: 'encode') { |i, _|
  i['phrase'].tr('., ', '').downcase.tr(alphabet, alphabet.reverse).each_char.each_slice(5).map(&:join).join(' ')
}

verify(json['cases'][1]['cases'], property: 'decode') { |i, _|
  i['phrase'].delete(' ').tr(alphabet, alphabet.reverse)
}
