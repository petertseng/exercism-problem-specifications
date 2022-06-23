require 'json'
require 'set'
require_relative '../../verify'

class Board
  def initialize(lines)
    @corners = Set.new
    @verticals = {}
    @horizontals = {}
    @width = lines.map(&:size).max || 0

    # Use lightweight disjoint set forest to check connectedness of two points.
    # One for horizontals and one for verticals.
    # Since any checked pair will share one dimension, it's fine to reuse IDs.

    # Iterate horizontally
    lines.each_with_index { |row, y|
      horiz_id = 0
      row.each_char.with_index { |c, x|
        if c == ?+
          pt = y * @width + x
          @corners << pt
          @horizontals[pt] = horiz_id
        end
        horiz_id += 1 if c != ?+ && c != ?-
      }
    }
    @corners.freeze
    @horizontals.freeze

    # Iterate vertically
    @width.times { |x|
      vert_id = 0
      lines.each_with_index { |row, y|
        c = row[x]
        @verticals[y * @width + x] = vert_id if c == ?+
        vert_id += 1 if c != ?+ && c != ?|
      }
    }
    @verticals.freeze
  end

  def rectangles(...)
    @corners.to_a.combination(2).count { |cs| rectangle?(*cs, ...) }
  end

  def rectangle?(p1, p2, ignore_missing_side: nil)
    raise "bad missing side #{ignore_missing_side}" if ignore_missing_side && !%i(up down left right).include?(ignore_missing_side)

    raise "#{p1} not corner" unless @corners.include?(p1)
    raise "#{p2} not corner" unless @corners.include?(p2)

    y1, x1 = p1.divmod(@width)
    y2, x2 = p2.divmod(@width)

    raise "combinations didn't come in order: #{p1.divmod(@width)} vs #{p2.divmod(@width)}" if y1 > y2

    # At this point, y1 <= y2.
    # No rectangles of zero height.
    return false if y1 == y2

    # At this point, y1 < y2.
    # No double-counting rectangles.
    # Require that p1 is the upper-left corner and p2 the lower-right.
    return false if x1 >= x2

    upper_left = p1
    lower_right = p2
    upper_right = y1 * @width + x2
    lower_left = y2 * @width + x1

    return false unless @corners.include?(upper_right)
    return false unless @corners.include?(lower_left)

    return false if ignore_missing_side != :up && @horizontals[upper_left] != @horizontals[upper_right]
    return false if ignore_missing_side != :down && @horizontals[lower_left] != @horizontals[lower_right]
    return false if ignore_missing_side != :left && @verticals[upper_left] != @verticals[lower_left]
    return false if ignore_missing_side != :right && @verticals[upper_right] != @verticals[lower_right]
    true
  end
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

multi_verify(json['cases'], property: 'rectangles', implementations: [
  {
    name: 'correct',
    f: ->(i, _) {
      Board.new(i['strings']).rectangles
    },
  },
] + %i(up down left right).map { |missing|
  {
    name: "missing #{missing}",
    should_fail: true,
    f: ->(i, _) {
      Board.new(i['strings']).rectangles(ignore_missing_side: missing)
    },
  }
})
