require 'json'
require_relative '../../verify'

DIRS = [-1, 0, 1].product([-1, 0, 1]).tap { |x| x.delete([0, 0]) }.freeze

def find_word(grid, word, dirs, starts, off_by_one: false)
  # one-index.
  coord = ->(y, x) {{'row' => y + 1, 'column' => x + 1}}

  (starts || []).product(dirs).each { |(y, x), (dy, dx)|
    next unless word.chars[0..(off_by_one ? -2 : -1)].each_with_index.all? { |c, i|
      cy = y + dy * i
      cx = x + dx * i
      next false if cy < 0 || cx < 0
      next false unless (row = grid[cy])
      row[cx] == c
    }
    d = word.size - 1
    return {
      'start' => coord[y, x],
      'end' => coord[y + d * dy, x + d * dx],
    }
  }
  nil
end

def find_words(grid, words, dirs, **kwargs)
  starts = grid.flat_map.with_index { |row, y|
    (0...row.size).map { |x| [y, x] }
  }.group_by { |y, x| grid[y][x] }
  words.to_h { |word| [word, find_word(grid, word, dirs, starts[word[0]], **kwargs)] }
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

dir_sets = [
  ['all', DIRS],
] + DIRS.map { |exclude| ["without #{exclude}", DIRS - [exclude]] }

multi_verify(json['cases'], property: 'search', implementations: dir_sets.map { |name, ds| {
  name: name,
  should_fail: ds.size < DIRS.size,
  f: ->(i, _) { find_words(i['grid'], i['wordsToSearchFor'], ds) },
}} + [{
  name: 'off-by-one',
  should_fail: true,
  f: ->(i, _) { find_words(i['grid'], i['wordsToSearchFor'], DIRS, off_by_one: true) },
}])
