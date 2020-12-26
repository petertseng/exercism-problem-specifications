require 'json'
require_relative '../../verify'

def run_ops(list, ops)
  ops.each_with_index { |op, j|
    expected_keys = case op['operation']
    when 'push'
      list << op['value']
      {value: :required}
    when 'unshift'
      list.unshift(op['value'])
      {value: :required}
    when 'pop'
      got = list.pop
      if (exp = op['expected'])
        raise TestFailure, "pop #{j} expected #{exp} but got #{got}" if got != exp
      end
      {expected: :optional}
    when 'shift'
      got = list.shift
      if (exp = op['expected'])
        raise TestFailure, "shift #{j} expected #{exp} but got #{got}" if got != exp
      end
      {expected: :optional}
    when 'count'
      got = list.size
      exp = op['expected']
      raise TestFailure, "count #{j} expected #{exp} but got #{got}" if got != exp
      {expected: :required}
    when 'delete'
      # Array#delete deletes them all; we only delete one.
      if (idx = list.index(op['value']))
        list.delete_at(idx)
      end
      {value: :required}
    else
      raise "bad operation #{op}"
    end

    expected_keys.merge!(operation: :required)
    raise "bad #{expected_keys}" unless expected_keys.values.all? { |v| %i(required optional).include?(v) }

    unexpected_keys = op.keys - expected_keys.keys.map(&:to_s)
    unless unexpected_keys.empty?
      raise "#{op} #{j} has unexpected keys #{unexpected_keys}"
    end
    missing_keys = expected_keys.filter_map { |k, v| k.to_s if v == :required } - op.keys
    unless missing_keys.empty?
      raise "#{op} #{j} has missing keys #{missing_keys}"
    end
  }
end

cases = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))['cases']

# Not the best fit for verify, since we just dispatch on operation and raise, accepting if we get to the end.
# However, this will change with the schema anyway, so we don't care.
verify(cases, accept: ->(_, _) { true }, property: 'list') { |i, _|
  lst = []
  run_ops(lst, i['operations'])
}
