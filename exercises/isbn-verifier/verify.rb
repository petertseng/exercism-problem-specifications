require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

def valid_isbn?(input)
  clean = input.delete(?-).chars
  return false if clean.size != 10

  digits = clean.map.with_index { |c, i|
    return false if c == ?X && i != clean.size - 1
    begin
      c == ?X ? 10 : Integer(c)
    rescue ArgumentError
      return false
    end
  }

  digits.reverse.map.with_index { |n, i| (i + 1) * n }.sum % 11 == 0
end

verify(json['cases'], property: 'isValid') { |i, _|
  valid_isbn?(i['isbn'])
}
