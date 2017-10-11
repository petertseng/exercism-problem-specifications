require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'countWords') { |i, _|
  i['sentence'].split(/[^'\w]/).reject(&:empty?).group_by { |x|
    (x[0] == ?' && x[-1] == ?' ? x[1...-1] : x).downcase
  }.transform_values(&:size)
}
