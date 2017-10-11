require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'].flat_map { |c| c['cases'] }, property: 'clean') { |i, _|
  num = i['phrase'].gsub(/\D/, '')
  num[0] == ?1 ? num = num[1..-1] : (raise 'bad country') if num.size == 11
  bad = '01'
  raise 'bad size' if num.size != 10
  raise 'bad area' if bad.include?(num[0])
  raise 'bad exchange' if bad.include?(num[3])
  num
}
