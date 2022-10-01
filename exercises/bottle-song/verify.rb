require 'json'
require_relative '../../verify'

CARDINAL = %w(no one two three four five six seven eight nine ten).map(&:freeze).freeze

def verse(n)
  pre = "#{bottles(n).to_s.capitalize} hanging on the wall,"
  post = "There'll be #{bottles(n - 1)} hanging on the wall."
  mid = 'And if one green bottle should accidentally fall,'

  [pre, pre, mid, post].map(&:freeze).freeze
end

def bottles(n)
  "#{CARDINAL.fetch(n)} green bottle#{?s if n != 1}"
end

module Intersperse refine Enumerable do
  def intersperse(x)
    map { |e| [x, e] }.flatten(1).drop(1)
  end
end end

using Intersperse

def verses(a, b)
  a.step(b, by: -1).map { |n| verse(n) }.intersperse('').flatten(1)
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'].flat_map { |c| c['cases'].flat_map { |cc| cc['cases'] } }, property: 'recite') { |i, _|
  verses(i['startBottles'], i['startBottles'] - i['takeDown'] + 1)
}
