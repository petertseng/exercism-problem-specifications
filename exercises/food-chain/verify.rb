require 'json'
require_relative '../../verify'

ANIMALS = [
  [:horse, 'She\'s dead, of course!'],
  [:cow, 'I don\'t know how she swallowed a cow!'],
  [:goat, 'Just opened her throat and swallowed a goat!'],
  [:dog, 'What a hog, to swallow a dog!'],
  [:cat, 'Imagine that, to swallow a cat!'],
  [:bird, 'How absurd to swallow a bird!'],
  [:spider, 'It', 'wriggled and jiggled and tickled inside her'],
  [:fly],
].map(&:freeze).freeze

def verse(n)
  animal, extra1, extra2 = ANIMALS[-n]
  punctuation = extra1&.end_with?(?!) ? '' : '.'
  [
    "I know an old lady who swallowed a #{animal}.",
    extra1 && [extra1, extra2].compact.join(' ') + punctuation,
  ].compact + (n >= ANIMALS.size ? [] : ANIMALS.last(n).each_cons(2).map { |(a, *), (b, _, c)|
    "She swallowed the #{a} to catch the #{b}#{c && " that #{c}"}."
  } << "I don't know why she swallowed the fly. Perhaps she'll die.")
end

module Intersperse refine Enumerable do
  def intersperse(x)
    map { |e| [x, e] }.flatten(1).drop(1)
  end
end end

using Intersperse

def verses(a, b)
  (a..b).map { |n| verse(n) }.intersperse('').flatten(1)
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'].flat_map { |c| c['cases'] }, property: 'recite') { |i, _|
  verses(i['startVerse'], i['endVerse'])
}
