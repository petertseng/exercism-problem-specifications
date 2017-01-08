require 'json'
require_relative '../../verify'

class Buf
  class Full < Exception; end
  class Empty < Exception; end

  # Not a real circular buffer.
  # I don't care, we just need to pass the tests.

  def initialize(capacity)
    @capacity = capacity
    @elts = []
  end

  def size
    @elts.size
  end

  def full?
    size == @capacity
  end

  def read
    @elts.shift || (raise Empty)
  end

  def write(x)
    raise Full if full?
    @elts << x
  end

  def overwrite(x)
    read if full?
    @elts << x
  end

  def clear
    @elts.clear
  end
end

cases = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))['cases']

# Not the best fit for verify, since we just dispatch on operation and raise, accepting if we get to the end.
# However, this will change with the schema anyway, so we don't care.
verify(cases, accept: ->(_, _) { true }, property: 'run') { |i, _|
  buf = Buf.new(i['capacity'])
  i['operations'].each_with_index { |op, j|
    case op['operation']
    when 'read'
      if op.fetch('should_succeed')
        got = buf.read
        raise "read #{j} expected #{op['expected']} but got #{got}" if got != op['expected']
      else
        begin
          got = buf.read
        rescue Buf::Empty
        else
          raise "read #{j} unexpectedly didn't fail (got #{got})"
        end
      end
    when 'write'
      if op.fetch('should_succeed')
        buf.write(op['item'])
      else
        begin
          buf.write(op['item'])
        rescue Buf::Full
        else
          raise "write #{j} unexpectedly didn't fail"
        end
      end
    when 'overwrite'; buf.overwrite(op['item'])
    when 'clear'; buf.clear
    end
  }
}
