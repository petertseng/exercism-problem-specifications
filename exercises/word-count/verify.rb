require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'countWords') { |i, _|
  i['sentence'].split(/[^'\w]/).map { |x| x.delete_prefix(?').delete_suffix(?').downcase }.reject(&:empty?).tally
}
