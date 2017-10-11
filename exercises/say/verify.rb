require 'json'
require_relative '../../verify'

ONES = ([''] + %w(one two three four five six seven eight nine)).map(&:freeze).freeze
TEENS = %w(ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen).map(&:freeze).freeze
TENS = (['', ''] + %w(twenty thirty forty fifty sixty seventy eighty ninety)).map(&:freeze).freeze

def say_under_thousand(ones_place, tens_place = 0, hundreds_place = 0)
  [
    ("#{ONES[hundreds_place]} hundred" if hundreds_place > 0),
    tens_place == 1 ? TEENS[ones_place] : [TENS[tens_place], ONES[ones_place]].reject(&:empty?).join(?-),
  ].compact.reject(&:empty?).join(' ')
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

MAGNITUDES = ['', ' thousand', ' million', ' billion'].map(&:freeze).freeze

verify(json['cases'], property: 'say') { |i, _|
  raise 'negative not allowed (though it would be easy)' if i['number'] < 0
  next 'zero' if i['number'] == 0

  parts = i['number'].digits.each_slice(3).map { |s| say_under_thousand(*s) }
  parts.zip(MAGNITUDES.take(parts.size)).map { |part, mag|
    raise 'too big (though it would be easy to add more)' unless mag
    part + mag unless part.empty?
  }.compact.reverse.join(' ')
}
