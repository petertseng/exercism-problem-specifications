require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

multi_verify(json['cases'], property: 'tick', implementations: [
  {
    name: 'correct',
    f: ->(i, _) {
      i['matrix'].map.with_index { |row, y|
        ys = (y == 0 ? y : y - 1)..(y + 1)
        row.map.with_index { |cur, x|
          xs = (x == 0 ? x : x - 1)..(x + 1)
          # 1 + 4 = 5
          # 1 + 6 = 7
          # 0 + 6 = 6
          (5..7).include?(ys.sum { |ny|
            next 0 unless nrow = i['matrix'][ny]
            xs.sum { |nx|
              (nrow[nx] || 0) << (ny == y && nx == x ? 0 : 1)
            }
          }) ? 1 : 0
        }
      }
    },
  },
  {
    name: 'wrap',
    should_fail: true,
    f: ->(i, _) {
      i['matrix'].map.with_index { |row, y|
        ys = (y - 1)..(y + 1)
        row.map.with_index { |cur, x|
          xs = (x - 1)..(x + 1)
          # 1 + 4 = 5
          # 1 + 6 = 7
          # 0 + 6 = 6
          (5..7).include?(ys.sum { |ny|
            next 0 unless nrow = i['matrix'][ny]
            xs.sum { |nx|
              (nrow[nx] || 0) << (ny == y && nx == x ? 0 : 1)
            }
          }) ? 1 : 0
        }
      }
    },
  },
])
