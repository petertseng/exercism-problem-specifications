require 'json'
require_relative '../../verify'

class Buf
  class Full < Exception; end
  class Empty < Exception; end

  # Not a real circular buffer.
  # I don't care, we just need to pass the tests.

  def initialize(capacity, broken: false)
    @capacity = capacity
    @elts = []
    @broken = broken
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
    read if full? || @broken
    @elts << x
  end

  def clear
    @elts.clear
  end
end

def run_ops(buf, ops)
  ops.each_with_index { |op, j|
    case op['operation']
    when 'read'
      if op.fetch('should_succeed')
        got = buf.read
        raise TestFailure, "read #{j} expected #{op['expected']} but got #{got}" if got != op['expected']
      else
        begin
          got = buf.read
        rescue Buf::Empty
        else
          raise TestFailure, "read #{j} unexpectedly didn't fail (got #{got})"
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
          raise TestFailure, "write #{j} unexpectedly didn't fail"
        end
      end
    when 'overwrite'; buf.overwrite(op['item'])
    when 'clear'; buf.clear
    end
  }
end

cases = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))['cases']

# Not the best fit for verify, since we just dispatch on operation and raise, accepting if we get to the end.
# However, this will change with the schema anyway, so we don't care.
multi_verify(cases, accept: ->(_, _) { true }, property: 'run', implementations: [false, true].map { |broken| {
  name: broken ? 'overwrite always drops' : 'correct',
  should_fail: broken,
  f: ->(i, _) {
    buf = Buf.new(i['capacity'], broken: broken)
    run_ops(buf, i['operations'])
  }
}})
