require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

def delta(coord, d)
  ->(p) { p.merge(coord => p[coord] + d) }
end

DIRS = {
  'north' => delta(?y, 1),
  'east' => delta(?x, 1),
  'south' => delta(?y, -1),
  'west' => delta(?x, -1),
}.each_value(&:freeze).freeze
dirs = DIRS.keys
RIGHT = dirs.zip(dirs.rotate(1)).to_h.each_value(&:freeze).freeze
LEFT = dirs.zip(dirs.rotate(-1)).to_h.each_value(&:freeze).freeze

cases = by_property(json['cases'].flat_map { |c| c['cases'] }, %w(create move))

verify(cases['create'], property: 'create') { |i, _| i }

verify(cases['move'], property: 'move') { |i, _|
  i['instructions'].each_char.reduce(i) { |r, c|
    case c
    when ?A; r.merge('position' => DIRS[r['direction']][r['position']])
    when ?L; r.merge('direction' => LEFT[r['direction']])
    when ?R; r.merge('direction' => RIGHT[r['direction']])
    else raise "Bad instruction #{c}"
    end
  }.select { |k, _| %w(position direction).include?(k) }
}
