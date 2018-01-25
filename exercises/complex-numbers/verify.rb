require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

props = {
  'real' => ->(c) { c[?z][0] },
  'imaginary' => ->(c) { c[?z][1] },
  'add' => ->(c) { z(c['z1']) + z(c['z2']) },
  'sub' => ->(c) { z(c['z1']) - z(c['z2']) },
  'mul' => ->(c) { z(c['z1']) * z(c['z2']) },
  'div' => ->(c) { z(c['z1']) / z(c['z2']) },
  'abs' => ->(c) { z(c[?z]).abs },
  'conjugate' => ->(c) { z(c[?z]).conjugate },
  'exp' => ->(c) { Math::E ** z(c[?z]) },
}.freeze

def z(r_and_i)
  Complex(*r_and_i.map { |x|
    case x
    when ?e;   Math::E
    when 'pi'; Math::PI
    when 'ln(2)'; Math.log(2)
    else x
    end
  })
end

cases = json['cases'].flat_map { |c| c.has_key?('cases') ? c['cases'].flat_map { |cc| cc['cases'] || cc } : c }
cases = by_property(cases, props.keys)

props.each { |prop, f|
  verify(cases.fetch(prop).map { |c|
    exp = c['expected']
    c.merge('expected' => exp.is_a?(Integer) ? exp : z(exp))
  }, property: prop) { |i, _|
    f[i]
  }
}
