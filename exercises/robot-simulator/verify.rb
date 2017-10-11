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

module Robot refine Hash do
  def right
    merge('direction' => RIGHT[self['direction']])
  end

  def left
    merge('direction' => LEFT[self['direction']])
  end

  def advance
    merge('position' => DIRS[self['direction']][self['position']])
  end
end end

using Robot

props = {
  'create' => ->(c) { c },
  'turnRight' => ->(c) { c.right },
  'turnLeft' => ->(c) { c.left },
  'advance' => ->(c) { c.advance },
  'instructions' => ->(c) { c['instructions'].each_char.reduce(c) { |r, i|
    case i
    when ?A; r.advance
    when ?L; r.left
    when ?R; r.right
    else raise "Bad instruction #{i}"
    end
  }},
}.freeze

if json['cases'].size != props.size
  keys = props.keys
  [json['cases'].size, props.size].max.times { |n|
    puts '%12s / %12s' % [json.dig('cases', n, 'cases', 0, 'property'), keys[n]]
  }
  raise 'Length mismatch'
end

json['cases'].zip(props) { |cs, (prop, f)|
  verify(cs['cases'], accept: ->(c, ans) { c['expected'] <= ans }, property: prop) { |i, _|
    f[i]
  }
}
