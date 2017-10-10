require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

OPPOSITE = {
  'left' => 'right'.freeze,
  'right' => 'left'.freeze,
}.freeze

def expected(e)
  case e['type']
  when 'int', 'tree'
    e['value']
  when 'zipper'
    e.has_key?('value') ? e['value'] : zipper(e['initialTree'], e['operations'])
  else raise "Unknown type #{e['type']} - #{e}"
  end
end

def tree(zipper)
  zipper[:context].empty? ? zipper[:tree].freeze : tree(up(zipper))
end

def up(zipper)
  return nil if zipper[:context].empty?
  direction, value, other = zipper[:context].first
  new_tree = {
    'value' => value,
    direction => zipper[:tree].freeze,
    OPPOSITE.fetch(direction) => other.freeze,
  }.freeze
  {tree: new_tree, context: zipper[:context][1..-1].freeze}.freeze
end

def zipper(initial_tree, ops)
  ops.reduce({tree: initial_tree.freeze, context: [].freeze}.freeze) { |zipper, op|
    case op['operation']
    when 'left', 'right'
      dir = op['operation']
      tree = zipper[:tree]
      tree[dir] && {
        tree: tree[dir],
        context: ([
          [dir, tree['value'], tree[OPPOSITE.fetch(dir)].freeze].freeze
        ] + zipper[:context]).freeze,
      }.freeze
    when 'to_tree'
      tree(zipper)
    when 'up'
      up(zipper)
    when 'value'
      zipper[:tree]['value']
    when /^set_(\w+)$/
      thing_to_set = $1
      zipper.merge(tree: zipper[:tree].merge(thing_to_set => op['item']).freeze).freeze
    else raise "Unknown operation #{op['operation']}: #{op}"
    end
  }
end

cases = by_property(json['cases'], %w(expectedValue sameResultFromOperations))

verify(cases['expectedValue'].map { |c| c.merge('expected' => c['expected']['value']) }, property: 'expectedValue') { |i, _|
  zipper(i['initialTree'], i['operations'])
}

verify(cases['sameResultFromOperations'].map { |c|
  exp = c['expected']
  c.merge('expected' => zipper(exp['initialTree'], exp['operations']))
}, property: 'sameResultFromOperations') { |i, _|
  zipper(i['initialTree'], i['operations'])
}
