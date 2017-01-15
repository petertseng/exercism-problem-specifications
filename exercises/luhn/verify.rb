require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

class LuhnError < StandardError; end

def map_luhn_digit(digit, double)
  begin
    digit = Integer(digit)
  rescue ArgumentError
    raise LuhnError
  end
  double && digit != 9 ? digit * 2 % 9 : digit
end

def valid_luhn?(input, map_digit = method(:map_luhn_digit))
  return false if input.strip.size < 2

  input.delete(' ').reverse.chars.zip([false, true].cycle).sum { |digit, double|
    map_digit[digit, double]
  } % 10 == 0
rescue LuhnError
  return false
end

verify(json['cases'], property: 'valid') { |i, _|
  valid_luhn?(i['value'])
}
