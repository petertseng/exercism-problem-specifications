require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

cases = by_property(json['cases'], %w(smallest largest))

# We can't actually get fancy here; searching by diagonal doesn't work.
# https://codereview.stackexchange.com/questions/63304/finding-palindromic-numbers-most-efficiently
# So just search linearly, trying to be a little smart:
# Terminate inner/outer searches when candidate can't beat winner.
# This is fast enough.
# If more is needed, maybe consider exploiting divisibility by 11,
# https://www.xarg.org/puzzle/project-euler/problem-4/
#
# (start: Int) number the search should start from.
# (range_from_start: Int => Range[Int]) make a range starting from the given start.
# (cmp: Symbol) symbol of comparison used to compare winner to a candidate
def palindromes(start, range_from_start, cmp)
  raise 'no' if range_from_start[start].size == 0

  winner = nil
  products = []
  range_from_start[start].each { |a|
    next if a % 10 == 0
    break if winner&.send(cmp, a * a)
    range_from_start[a].each { |b|
      product = a * b
      break if winner&.send(cmp, product)
      next if (d = product.digits).reverse != d
      if product == winner
        products << [a, b].sort
      else
        winner = product
        products = [[a, b].sort]
      end
    }
  }
  {'value' => winner, 'factors' => products}
end

def smallest(min, max)
  palindromes(min, ->x { x..max }, :<)
end

def largest(min, max)
  palindromes(max, ->x { x.downto(min) }, :>)
end

verify(cases['smallest'], property: 'smallest') { |i, _|
  smallest(i['min'], i['max'])
}

verify(cases['largest'], property: 'largest') { |i, _|
  largest(i['min'], i['max'])
}
