require 'json'
require_relative '../../verify'

DIRS = [-1, 0, 1].product([-1, 0, 1]).tap { |x| x.delete([0, 0]) }.freeze

def find_word(grid, word, dirs, starts)
  # one-index.
  coord = ->(y, x) {{'row' => y + 1, 'column' => x + 1}}

  (starts || []).product(dirs).each { |(y, x), (dy, dx)|
    next unless word.each_char.with_index.all? { |c, i|
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

def find_words(grid, words, dirs)
  starts = grid.flat_map.with_index { |row, y|
    (0...row.size).map { |x| [y, x] }
  }.group_by { |y, x| grid[y][x] }
  words.to_h { |word| [word, find_word(grid, word, dirs, starts[word[0]])] }
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'search') { |i, _|
  find_words(i['grid'], i['wordsToSearchFor'], DIRS)
}
