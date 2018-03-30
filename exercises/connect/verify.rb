require 'json'
require 'set'
require_relative '../../verify'

class Board
  DIRECTIONS = [
    [-1, 0],
    [-1, 1],
    [0, -1],
    [0, 1],
    [1, -1],
    [1, 0],
  ].freeze.each(&:freeze)

  def initialize(lines, directions)
    @lines = lines.map { |l| l.tr(' ', '') }
    @rows = lines.size
    @columns = @lines.empty? ? 0 : @lines.first.size
    # Strictly speaking, we *could* support jagged boards,
    # but it'd require extra code that has just not been written.
    raise "unequal row lengths (#{@lines.map(&:size)})" unless @lines.all? { |l| l.size == @columns }
    @directions = directions
  end

  def x_wins?
    starts = (0..@rows).map { |r| [r, 0].freeze }
    player_wins?(starts, ?X.freeze, ->(_r, c) { c == @columns - 1 })
  end

  def o_wins?
    starts = (0..@columns).map { |c| [0, c].freeze }
    player_wins?(starts, ?O.freeze, ->(r, _c) { r == @rows - 1 })
  end

  def player_wins?(starts, player, goal)
    seen = Set.new

    can_reach_goal = ->(coord) {
      seen << coord
      goal[*coord] || neighbours(coord, player).any? { |n| !seen.include?(n) && can_reach_goal[n] }
    }

    starts.any? { |start| at(*start) == player && can_reach_goal[start] }
  end

  def neighbours((r, c), player)
    @directions.map { |dr, dc| [r + dr, c + dc].freeze }.select { |neighbour|
      at(*neighbour) == player
    }
  end

  def at(row, column)
    (line = @lines[row]) && line[column]
  end

  def winner
    @winner ||= (x_wins? ? ?X : o_wins? ? ?O : '').freeze
  end
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

dir_sets = [
  ['all', Board::DIRECTIONS],
] + Board::DIRECTIONS.map { |exclude|
  ["without #{exclude}", Board::DIRECTIONS - [exclude]]
} + [[-1, -1], [1, 1]].map { |add|
  ["with #{add}", Board::DIRECTIONS + [add]]
}

multi_verify(json['cases'], property: 'winner', implementations: dir_sets.map { |name, ds| {
  name: name,
  should_fail: ds.size != Board::DIRECTIONS.size,
  f: ->(i, c) { Board.new(i['board'], ds).winner },
}})
