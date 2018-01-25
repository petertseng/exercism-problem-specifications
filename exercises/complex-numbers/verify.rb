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
  # Note that Math.exp can't be used here since it only accepts real numbers.
  'exp' => ->(c) { Math::E ** z(c[?z]) },
}.freeze

def z(r_and_i)
  case r_and_i
  when Integer
    r_and_i
  when Array
    Complex(*r_and_i.map { |x|
      case x
      when ?e;   Math::E
      when 'pi'; Math::PI
      when 'pi/4'; Math::PI / 4
      when 'ln(2)'; Math.log(2)
      when 'ln(2)/2'; Math.log(2) / 2
      else x
      end
    })
  else
    raise "bad #{r_and_i}"
  end
end

cases = json['cases'].flat_map { |c| c.has_key?('cases') ? c['cases'].flat_map { |cc| cc['cases'] || cc } : c }
cases = by_property(cases, props.keys)

props.each { |prop, f|
  verify(cases.fetch(prop).map { |c|
    exp = c['expected']
    c.merge('expected' => exp.is_a?(Integer) ? exp : z(exp))
  }, property: prop, accept: ->(c, ans) {
    exp = c['expected']
    exp == ans || begin
      puts "\e[1;33mTolerance checking #{exp} vs #{ans}\e[0m"
      exp.real == ans.real && ans.imaginary.is_a?(Float) && (ans.imaginary - exp.imaginary).abs <= Float::EPSILON
    end

  }) { |i, _|
    f[i]
  }
}
