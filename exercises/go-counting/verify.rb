require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

cases = by_property(json['cases'], %w(territory territories))

class UnionFind
  def initialize(things)
    @parent = things.to_h { |x| [x, x] }
    @rank = things.to_h { |x| [x, 0] }
    @frozen = false
  end

  def keys
    @parent.keys
  end

  def union(x, y)
    raise FrozenError if @frozen
    xp = find(x)
    yp = find(y)

    return if xp == yp

    if @rank.fetch(xp) < @rank.fetch(yp)
      @parent[xp] = yp
    elsif @rank.fetch(xp) > @rank.fetch(yp)
      @parent[yp] = xp
    else
      @parent[yp] = xp
      @rank[xp] += 1
    end
  end

  def find(x)
    @parent[x] = find(@parent.fetch(x)) if @parent.fetch(x) != x
    @parent.fetch(x)
  end

  def freeze
    @frozen = true
    self
  end
end

module EachGridPair refine Array do
  def each_grid_pair
    each_with_index { |row, y|
      row.each_char.with_index { |c, x|
        [[y + 1, x], [y, x + 1]].each { |y2, x2|
          next unless (c2 = self[y2]&.[](x2))
          yield c, [y, x], c2, [y2, x2]
        }
      }
    }
  end
end end

using EachGridPair

def territories(board)
  # Collect connected points without a stone into regions.
  uf = UnionFind.new(board.each_with_index.flat_map { |row, y| row.size.times.map { |x| [y, x] } })
  board.each_grid_pair { |c1, place1, c2, place2|
    uf.union(place1, place2) if c1 == ' ' && c2 == ' '
  }
  uf.freeze
  regions = uf.keys.group_by { |k| uf.find(k) }.select { |(y, x), _| board[y][x] == ' ' }

  # For each region, mark which stones border it.
  colours = regions.transform_values { [false, false] }
  board.each_grid_pair { |c1, place1, c2, place2|
    # Only consider pairs where exactly one is a stone.
    next if (c1 == ' ') == (c2 == ' ')
    place = c1 == ' ' ? place1 : place2
    # sort places ' ' before ?B and ?W, so .sort.last gets us the colour.
    # arbitrarily assign black index 0 and white 1.
    colour = [c1, c2].sort.last == ?B ? 0 : 1
    colours.fetch(uf.find(place))[colour] = true
  }

  # Based on which stones border each region, determine an owner.
  colours.transform_values! { |black, white|
    # Only one colour => that colour is owner.
    # Either or both => no owner.
    (black && !white ? 'BLACK' : white && !black ? 'WHITE' : nil).freeze
  }

  regions.map { |representative, territory|
    {
      'owner' => (colours.fetch(representative) || 'NONE').freeze,
      # The canonical data has chosen to use [x, y], unlike our [y, x]
      'territory' => territory.map(&:reverse).map(&:freeze).sort.freeze,
    }
  }.freeze
end

verify(cases['territory'], property: 'territory') { |i, _|
  y, x = i.values_at(?y, ?x)
  raise 'invalid coord' if x < 0 || y < 0
  raise 'invalid coord' unless i['board'][y][x]
  territories(i['board']).find { |t|
    t['territory'].include?([x, y])
  } || {'owner' => 'NONE', 'territory' => []}
}

verify(cases['territories'], property: 'territories') { |i, _|
  default = {
    'territoryBlack' => [],
    'territoryWhite' => [],
    'territoryNone' => [],
  }

  # Three possible options for how to show the output:
  # https://github.com/exercism/problem-specifications/pull/1195#pullrequestreview-99863372
  # I didn't like by_owner_combined since it doesn't differentiate regions,
  # but it looks like nobody else cares :)
  case which_output_type_should_we_use = :by_owner_combined
  when :array_of_territory
    territories(i['board'])
  when :by_owner
    default.merge(territories(i['board']).group_by { |t| t['owner'] }.to_h { |k, vs|
      ['territory' + k.capitalize, vs.map { |t| t['territory'] }.sort.freeze]
    })
  when :by_owner_combined
    default.merge(territories(i['board']).group_by { |t| t['owner'] }.to_h { |k, vs|
      ['territory' + k.capitalize, vs.flat_map { |t| t['territory'] }.sort.freeze]
    })
  end
}
