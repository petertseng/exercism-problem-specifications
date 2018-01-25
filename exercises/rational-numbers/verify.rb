require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

props = {
  'add' => ->(c) { rat(c['r1']) + rat(c['r2']) },
  'sub' => ->(c) { rat(c['r1']) - rat(c['r2']) },
  'mul' => ->(c) { rat(c['r1']) * rat(c['r2']) },
  'div' => ->(c) { rat(c['r1']) / rat(c['r2']) },
  'abs' => ->(c) { rat(c[?r]).abs },
  'exprational' => ->(c) { rat(c[?r]) ** c[?n] },
  'expreal' => ->(c) {
    # Unfortunate. 4096 ** (1.0 / 3.0) is 15.999999999999998 instead of 16.0
    n = c[?x] ** c[?r][0]
    c[?r][1] == 3 ? Math::cbrt(n) : n ** (1.0 / c[?r][1])
  },
  'reduce' => ->(c) { rat(c[?r]) },
}.freeze

def rat(n_and_d)
  Rational(*n_and_d)
end

cases = json['cases'].flat_map { |c| c.has_key?('cases') ? c['cases'].flat_map { |cc| cc['cases'] || cc } : c }
cases = by_property(cases, props.keys)

props.each { |prop, f|
  verify(cases.fetch(prop).map { |c|
    exp = c['expected']
    c.merge('expected' => exp.is_a?(Numeric) ? exp : rat(exp))
  }, property: prop) { |i, _|
    f[i]
  }
}
