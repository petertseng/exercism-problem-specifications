require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'transform') { |i, _|
  i['legacy'].flat_map { |score, letters|
    letters.map { |letter| [letter.downcase, score.to_i] }
  }.to_h
}
