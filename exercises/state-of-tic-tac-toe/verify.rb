require 'json'
require 'set'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

def board_stat(lines)
  rows = lines.map(&:chars)
  cells = lines.join

  row_wins = (0..2).map { |y| (0..2).map { |x| [y, x] } }
  col_wins = (0..2).map { |y| (0..2).map { |x| [x, y] } }
  diag1 = (0..2).map { |x| [x, x] }
  diag2 = (0..2).map { |x| [x, 2 - x] }

  wins = row_wins + col_wins + [diag1, diag2]

  {
    x_win: wins.count { |coord| coord.all? { |c| rows.dig(*c) == ?X } },
    o_win: wins.count { |coord| coord.all? { |c| rows.dig(*c) == ?O } },
    x: cells.count(?X),
    o: cells.count(?O),
  }
end

verify(json['cases'].flat_map { |c| c['cases'] }, property: 'gamestate') { |i, c|
  stat = board_stat(i['board'])
  raise 'bad turn' unless (0..1).cover?(stat[:x] - stat[:o])
  raise 'both players won' if stat[:x_win] > 0 && stat[:o_win] > 0

  if stat[:x_win] > 0
    raise "#{stat[:o]} wasn't #{stat[:x] - 1}" if c['uuid'] != '108a5e82-cc61-409f-aece-d7a18c1beceb' && stat[:o] != stat[:x] - 1
    'win'
  elsif stat[:o_win] > 0
    raise "#{stat[:x]} wasn't #{stat[:o]}" if stat[:x] != stat[:o]
    'win'
  elsif stat[:x] == 5 && stat[:o] == 4
    'draw'
  else
    'ongoing'
  end
}
