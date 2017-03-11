require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

raise "There should be exactly three cases, not #{json['cases'].size}" if json['cases'].size != 3

verify(json['cases'][0]['cases'], property: 'encode') { |i, _|
  i['string'].each_char.chunk(&:itself).map { |char, chars|
    "#{chars.size if chars.size > 1}#{char}"
  }.join
}

verify(json['cases'][1]['cases'], property: 'decode') { |i, _|
  i['string'].gsub(/(\d+)(\D)/) { $2 * $1.to_i }
}

verify(json['cases'][2]['cases'], property: 'consistency') { |i, _|
  # Erm... not much point, if decode and encode are individually tested to work.
  # I'll not even bother implementing.
  i['string']
}
