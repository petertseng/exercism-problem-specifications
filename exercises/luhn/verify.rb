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

multi_verify(json['cases'], property: 'valid', implementations: [
  {
    name: 'correct',
    f: ->(i, _) { valid_luhn?(i['value']) },
  },
  {
    name: 'reverse',
    should_fail: true,
    f: ->(i, _) { valid_luhn?(i['value'].reverse) },
  },
  {
    name: 'reverse will work if prepending 0 to even-length',
    f: ->(i, _) {
      # Note that wikipedia says to prepend 0 to odd-length
      # and double digits in the odd positions.
      # However, since I double digits in the even positions,
      # that means I must prepend 0 to even length.
      v = i['value'].delete(' ')
      return false if v.size <= 1
      valid_luhn?((v.size.odd? ? v : ?0 + v).reverse)
    },
  },
  {
    # https://github.com/exercism/problem-specifications/pull/1500
    name: 'reverse and always flip polarity',
    should_fail: true,
    f: ->(i, _) {
      valid_luhn?(i['value'].reverse, ->(digit, double) {
        map_luhn_digit(digit, !double)
      })
    },
  },
  {
    # https://github.com/exercism/problem-specifications/pull/1500
    name: 'reverse and conditionally flip polarity if odd length (w/ spaces)',
    should_fail: true,
    f: ->(i, _) {
      valid_luhn?(i['value'].reverse, ->(digit, double) {
        map_luhn_digit(digit, double ^ i['value'].size.odd?)
      })
    },
  },
  {
    name: 'reverse and conditionally flip polarity if odd length (w/o spaces)',
    should_fail: true,
    f: ->(i, _) {
      v = i['value'].delete(' ')
      valid_luhn?(v.reverse, ->(digit, double) {
        map_luhn_digit(digit, double ^ v.size.odd?)
      })
    },
  },
  {
    # https://github.com/exercism/problem-specifications/pull/1500
    name: 'reverse and conditionally flip polarity if even length (w/ spaces)',
    should_fail: true,
    f: ->(i, _) {
      valid_luhn?(i['value'].reverse, ->(digit, double) {
        map_luhn_digit(digit, double ^ i['value'].size.even?)
      })
    },
  },
  {
    name: 'reverse and conditionally flip polarity if even length (w/o spaces)',
    # I think this works.
    f: ->(i, _) {
      v = i['value'].delete(' ')
      valid_luhn?(v.reverse, ->(digit, double) {
        map_luhn_digit(digit, double ^ v.size.even?)
      })
    },
  },
  {
    # https://github.com/exercism/problem-specifications/pull/1246
    name: 'blindly converting everything to a digit',
    should_fail: true,
    f: ->(i, _) {
      valid_luhn?(i['value'], ->(digit, double) {
        # The != 9 and % 9 in map_luhn_digit are more clever than they should be.
        # The description only says to subtract 9 once.
        # Following it very strictly gives this:
        d = digit.ord - ?0.ord
        d *= 2 if double
        double && d > 9 ? d - 9 : d
      })
    }
  },
  {
    # https://github.com/exercism/problem-specifications/pull/1480
    name: 'trying to be too clever with integer division',
    should_fail: true,
    f: ->(i, _) {
      valid_luhn?(i['value'], ->(digit, double) {
        d = digit.ord - ?0.ord
        double ? d * 2 - 9 * (d / 5) : d
      })
    }
  },
])
