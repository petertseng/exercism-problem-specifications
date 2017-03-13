require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'isIsogram') { |i, _|
  (cs = i['phrase'].tr(' -', '').downcase.chars).size == cs.uniq.size
}
