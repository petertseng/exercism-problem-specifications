require 'json'
require_relative '../../verify'

def verse(n)
  pre = "#{bottles(n).to_s.capitalize} on the wall, #{bottles(n)}."
  post = ", #{bottles((n - 1) % 100)} on the wall."
  mid = case n
    when 0; 'Go to the store and buy some more'
    when 1; 'Take it down and pass it around'
    else 'Take one down and pass it around'
  end

  [pre, mid + post]
end

def bottles(n)
  "#{n == 0 ? 'no more' : n} bottle#{?s if n != 1} of beer"
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
