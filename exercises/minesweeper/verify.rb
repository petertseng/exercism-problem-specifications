require 'json'
require_relative '../../verify'

def mines(board)
  board.flat_map.with_index { |row, y|
    (0...row.size).select { |x| row[x] == ?* }.map { |x| [y, x] }
  }
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

verify(json['cases'], property: 'annotate') { |i, _|
  annotate(i['minefield'], method(:mines))
}
