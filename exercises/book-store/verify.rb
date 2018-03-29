require 'json'
require_relative '../../verify'

# return Hash[book => frequency of that book]
def by_count(books)
  books.group_by(&:itself).transform_values(&:size)
end

def price(groups)
  groups.sum { |g|
    case g.size
    when 1; 800
    when 2; 1520
    when 3; 2160
    when 4; 2560
    when 5; 3000
    else raise "Improper group #{g}"
    end
  }
end

# groups: already grouped books
# books: books that still need to be added to groups
def try_best(groups, books, cache = {})
  return price(groups) if books.empty?

  # take the first book in the list,
  # add it to each possible group in succession,
  # recurse with remaining books.
  book, *remain_books = books

  cache[groups] ||= groups.map.with_index { |g, i|
    next if g.include?(book)
    new_groups = (groups.take(i) + groups.drop(i + 1) << (g + [book]).sort).sort
    try_best(new_groups, remain_books, cache)
  }.compact.min
end

def best_price(books)
  return 0 if books.empty?

  counts = by_count(books)
  # Put the most numerous book(s) in all groups.
  max_count = counts.values.max
  max_books = counts.select { |k, v| v == max_count }.keys.freeze
  max_books.each { |mb| counts.delete(mb) }
  starter_groups = ([max_books] * max_count).freeze

  remaining_books = books.reject { |b| max_books.include?(b) }

  try_best(starter_groups, remaining_books)
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

multi_verify(json['cases'], property: 'total', implementations: [
  {
    name: 'correct',
    f: ->(i, _) { best_price(i['basket']) },
  },
  {
    name: 'greedy',
    should_fail: true,
    f: ->(i, _) {
      counts = by_count(i['basket'])
      next 0 if i['basket'].empty?
      (1..counts.values.max).sum { |n|
        price([[nil] * counts.count { |_, v| v >= n }])
      }
    },
  },
])
