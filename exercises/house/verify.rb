require 'json'
require_relative '../../verify'

THINGS = [
  "the horse and the hound and the horn\nthat belonged to ",
  "the farmer sowing his corn\nthat kept ",
  "the rooster that crowed in the morn\nthat woke ",
  "the priest all shaven and shorn\nthat married ",
  "the man all tattered and torn\nthat kissed ",
  "the maiden all forlorn\nthat milked ",
  "the cow with the crumpled horn\nthat tossed ",
  "the dog\nthat worried ",
  "the cat\nthat killed ",
  "the rat\nthat ate ",
  "the malt\nthat lay in ",
  'the house that Jack built',
].map(&:freeze).freeze

ONE_LINE_PER_VERSE = true

def verse(n)
  lines = "This is #{THINGS.last(n).join}.".lines
  ONE_LINE_PER_VERSE ? lines.join.tr("\n", ' ') : lines.map(&:chomp)
end

module Intersperse refine Enumerable do
  def intersperse(x)
    map { |e| [x, e] }.flatten(1).drop(1)
  end
end end

using Intersperse

def verses(a, b)
  verses = (a..b).map { |n| verse(n) }
  verses = verses.intersperse('') unless ONE_LINE_PER_VERSE
  verses.flatten(1)
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'recite') { |i, _|
  verses(i['startVerse'], i['endVerse'])
}
