require 'json'
require_relative '../../verify'

def reflect(target)
  target.concat(target[0...-1].reverse)
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'rows') { |i, _|
  width = i['letter'].ord - ?A.ord
  lines = (?A..i['letter']).map.with_index { |letter, j|
    left_half = "#{' ' * (width - j)}#{letter}#{' ' * j}"
    reflect(left_half)
  }
  reflect(lines)
}
