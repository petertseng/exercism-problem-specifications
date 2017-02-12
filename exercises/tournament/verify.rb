require 'json'
require_relative '../../verify'

class Team
  attr_reader :name

  def initialize(name)
    @name = name.freeze
    @wins = 0
    @losses = 0
    @draws = 0
  end

  def plays
    @wins + @losses + @draws
  end

  def points
    @wins * 3 + @draws
  end

  def win
    @wins += 1
  end

  def lose
    @losses += 1
  end

  def draw
    @draws += 1
  end

  def to_s
    '%-30s | %2d | %2d | %2d | %2d | %2d' % [@name, plays, @wins, @draws, @losses, points]
  end
end

HEADER = ('%-30s | MP |  W |  D |  L |  P' % 'Team').freeze

def tally(lines)
  teams = Hash.new { |h, k| h[k] = Team.new(k) }
  lines.each { |line|
    # TODO: Doesn't make sense that we ignore invalid lines. We should error.
    parts = line.chomp.split(?;)
    next unless parts.size == 3
    t1, t2, r = parts
    next unless %w(win loss draw).include?(r)
    t1 = teams[t1]
    t2 = teams[t2]
    case r
    when 'win'
      t1.win
      t2.lose
    when 'loss'
      t2.win
      t1.lose
    when 'draw'
      t1.draw
      t2.draw
    end
  }
  HEADER + "\n" + teams.values.sort_by { |t| [-t.points, t.name] }.join("\n")
end

data = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(data['cases'], property: 'tally') { |i, _|
  tally(i['rows']).lines.map(&:chomp)
}
