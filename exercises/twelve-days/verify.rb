require 'json'
require_relative '../../verify'

DAYS = {
  twelfth: 'twelve Drummers Drumming',
  eleventh: 'eleven Pipers Piping',
  tenth: 'ten Lords-a-Leaping',
  ninth: 'nine Ladies Dancing',
  eighth: 'eight Maids-a-Milking',
  seventh: 'seven Swans-a-Swimming',
  sixth: 'six Geese-a-Laying',
  fifth: 'five Gold Rings',
  fourth: 'four Calling Birds',
  third: 'three French Hens',
  second: 'two Turtle Doves',
  first: 'a Partridge in a Pear Tree',
}.each_value(&:freeze).freeze

def list(things)
  things.size == 1 ? things[0] : (things[0...-1] << "and #{things[-1]}").join(', ')
end

def verse(n)
  ordinal = DAYS.keys[-n]
  gifts = DAYS.values.last(n)
  "On the #{ordinal} day of Christmas my true love gave to me: #{list(gifts)}."
end

def verses(a, b)
  (a..b).map { |n| verse(n) }
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

raise "There should be exactly two cases, not #{json['cases'].size}" if json['cases'].size != 2

verify(json['cases'].flat_map { |c| c['cases'] }, property: 'recite') { |i, _|
  verses(i['startVerse'], i['endVerse'])
}
