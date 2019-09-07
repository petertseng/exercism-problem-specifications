require 'json'
require 'set'
require_relative '../../verify'

module Coordinate refine Array do
  alias :y :first
  alias :x :last

  def opposites((y2, x2))
    [
      [y, x2],
      [y2, x],
    ]
  end
end end

class Board
  using Coordinate

  def initialize(lines)
    @corners = Set.new
    @verticals = {}
    @horizontals = {}

    # Use lightweight disjoint set forest to check connectedness of two points.
    # One for horizontals and one for verticals.
    # Since any checked pair will share one dimension, it's fine to reuse IDs.

    # Iterate horizontally
    lines.each_with_index { |row, y|
      horiz_id = 0
      row.each_char.with_index { |c, x|
        if c == ?+
          pt = [y, x].freeze
          @corners << pt
          @horizontals[pt] = horiz_id
        end
        horiz_id += 1 if c != ?+ && c != ?-
      }
    }
    @corners.freeze
    @horizontals.freeze

    # Iterate vertically
    (lines.map(&:size).max || 0).times { |x|
      vert_id = 0
      lines.each_with_index { |row, y|
        c = row[x]
        @verticals[[y, x].freeze] = vert_id if c == ?+
        vert_id += 1 if c != ?+ && c != ?|
      }
    }
    @verticals.freeze
  end

  def rectangles
    @corners.to_a.combination(2).count { |cs| rectangle?(*cs) }
  end

  def rectangle?(p1, p2)
    upper_left, lower_right = [p1, p2].sort
    # you'd think that this should be upper_left.y >= lower_right.y,
    # but the sort makes the > case impossible, so we only need to check ==.
    # and == has been observed to be slightly faster than >=
    # (3.8 seconds vs 4.1 seconds to do 30x30 grid)
    return false if upper_left.y == lower_right.y || upper_left.x >= lower_right.x
    opposites = upper_left.opposites(lower_right)
    return false unless opposites.all? { |o| @corners.include?(o) }
    [upper_left, lower_right].product(opposites).all? { |pts| connected?(*pts) }
  end

  def connected?(p1, p2)
    p1, p2 = [p1, p2].sort
    return @horizontals[p1] == @horizontals[p2] if p1.y == p2.y
    return @verticals[p1] == @verticals[p2] if p1.x == p2.x
    raise "#{p1}, #{p2} aren't in a line"
  end
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'rectangles') { |i, _|
  Board.new(i['strings']).rectangles
}
