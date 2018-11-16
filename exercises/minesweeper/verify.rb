require 'json'
require_relative '../../verify'

def mines(board)
  board.flat_map.with_index { |row, y|
    (0...row.size).select { |x| row[x] == ?* }.map { |x| [y, x] }
  }
end

def mirrored_mines(board)
  # https://github.com/exercism/haskell/pull/284
  # https://github.com/exercism/haskell/pull/770
  # actually the Haskell impl mirrored the output mine locations too.
  # this one only mirrors the counts, not the output mines.
  height = board.size
  width = board[0].size
  # fundamental problem was `listArray (1, 1) (X, Y)`
  # That counts in order (1, 1), (1, 2) ... (1, Y), (2, 1) ...
  # But the `concat` meant that it should be X increasing first.
  new_coords = (0...width).to_a.product((0...height).to_a).map(&:reverse)
  board.join.each_char.zip(new_coords).select { |c, _| c == ?* }.map(&:last)
end

def annotate(board, mines)
  return board if board.empty?
  width = board[0].size
  raise "Sizes: #{board.map(&:size)}" if board.any? { |r| r.size != width }

  counts = mines[board].flat_map { |y, x|
    [-1, 0, 1].product([-1, 0, 1]).map { |dy, dx| [y + dy, x + dx] }
  }.group_by(&:itself)

  board.map.with_index { |row, y|
    row.each_char.map.with_index { |c, x|
      (n = counts[[y, x]]) && c == ' ' ? n.size : c
    }.join
  }
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'].map { |c|
  c.merge('expected' => c['expected'].map { |l| l.gsub(/\d/, ' ') })
}, property: 'annotate') { |i, _|
  i['minefield']
}

multi_verify(json['cases'], property: 'annotate', implementations: [
  {
    name: 'correct',
    f: ->(i, _) {
      annotate(i['minefield'], method(:mines))
    }
  },
  {
    name: 'mirrored',
    should_fail: true,
    f: ->(i, _) {
      annotate(i['minefield'], method(:mirrored_mines))
    }
  },
])
