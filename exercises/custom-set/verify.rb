require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

props = {
  'empty' => ->(c) { c['set'].empty? },
  'contains' => ->(c) { c['set'].include?(c['element']) },
  'subset' => ->(c) { c['set1'].all? { |e| c['set2'].include?(e) } },
  'disjoint' => ->(c) { (c['set1'] & c['set2']).empty? },
  'equal' => ->(c) { c['set1'].uniq.sort == c['set2'].uniq.sort },
  'add' => ->(c) { c['set'] + [c['element']] },
  'intersection' => ->(c) { c['set1'] & c['set2'] },
  'difference' => ->(c) { c['set1'] - c['set2'] },
  'union' => ->(c) { c['set1'] | c['set2'] },
}.freeze

def set(maybe_set)
  return maybe_set unless maybe_set.is_a?(Array)
  maybe_set.uniq.sort
end

if json['cases'].size != props.size
  keys = props.keys
  [json['cases'].size, props.size].max.times { |n|
    puts '%12s / %12s' % [json.dig('cases', n, 'cases', 0, 'property'), keys[n]]
  }
  raise 'Length mismatch'
end

json['cases'].zip(props) { |cs, (prop, f)|
  verify(cs['cases'].map { |c| c.merge('expected' => set(c['expected'])) }, property: prop) { |i, _|
    set(f[i])
  }
}
