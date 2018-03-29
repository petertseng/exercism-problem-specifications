require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

class BadLengthError < Exception; end

def valid_isbn?(input, strict_x: true)
  clean = input.delete(?-).chars
  begin
    clean = yield clean if block_given?
  rescue BadLengthError
    return false
  end

  digits = clean.map.with_index { |c, i|
    return false if c == ?X && strict_x && i != clean.size - 1
    begin
      c == ?X ? 10 : Integer(c)
    rescue ArgumentError
      return false
    end
  }

  digits.reverse.map.with_index { |n, i| (i + 1) * n }.sum % 11 == 0
end

multi_verify(json['cases'], property: 'isValid', implementations: [
  {
    name: 'correct',
    f: ->(i, _) {
      valid_isbn?(i['isbn']) { |x| raise BadLengthError if x.size != 10; x }
    },
  },
  {
    name: 'fun fact, all ISBN w/o X are valid even if reversed!',
    f: ->(i, _) {
      valid_isbn?(i['isbn']) { |x|
        raise BadLengthError if x.size != 10
        x.include?(?X) ? x : x.reverse
      }
    },
  },
  {
    # https://github.com/exercism/problem-specifications/pull/993
    name: 'X is always 10',
    should_fail: true,
    f: ->(i, _) {
      valid_isbn?(i['isbn'], strict_x: false) { |x| raise BadLengthError if x.size != 10; x }
    },
  },
  {
    # https://github.com/exercism/problem-specifications/issues/1199
    name: 'too long -> all digits',
    should_fail: true,
    f: ->(i, _) {
      valid_isbn?(i['isbn']) { |x| raise BadLengthError if x.size < 10; x }
    },
  },
  {
    # https://github.com/exercism/problem-specifications/issues/1199
    name: 'too long -> left 10',
    should_fail: true,
    f: ->(i, _) {
      valid_isbn?(i['isbn']) { |x| raise BadLengthError if x.size < 10; x.take(10) }
    },
  },
  {
    # https://github.com/exercism/problem-specifications/issues/1199
    name: 'too long -> right 10',
    should_fail: true,
    f: ->(i, _) {
      valid_isbn?(i['isbn']) { |x| raise BadLengthError if x.size < 10; x.last(10) }
    },
  },
  {
    # https://github.com/exercism/problem-specifications/issues/1223
    name: 'too short -> prepend zero',
    should_fail: true,
    f: ->(i, _) {
      valid_isbn?(i['isbn']) { |x| raise BadLengthError unless (1..10).cover?(x.size); x.unshift(0) until x.size >= 10; x }
    },
  },
  {
    # https://github.com/exercism/problem-specifications/issues/1216
    name: 'too short -> append zero',
    should_fail: true,
    f: ->(i, _) {
      valid_isbn?(i['isbn']) { |x| raise BadLengthError unless (1..10).cover?(x.size); x << 0 until x.size >= 10; x }
    },
  },
  {
    # https://github.com/exercism/problem-specifications/issues/1212
    name: 'invalid middle -> becomes zero',
    should_fail: true,
    f: ->(i, _) {
      replace = (?A...?X).to_a + [?Y, ?Z]
      valid_isbn?(i['isbn']) { |x| raise BadLengthError if x.size != 10; x.map { |d| replace.include?(d) ? 0 : d } }
    },
  },
  {
    # https://github.com/exercism/problem-specifications/issues/1216
    name: 'invalid middle -> dropped',
    should_fail: true,
    f: ->(i, _) {
      drop = (?A...?X).to_a + [?Y, ?Z]
      valid_isbn?(i['isbn']) { |x| raise BadLengthError if x.size != 10; x.reject { |d| drop.include?(d) } }
    },
  },
])
