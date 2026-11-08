require 'json'
require_relative '../../verify'

def run_ops(ops, mode: nil)
  list = ops['initialValues']

  ops['operations'].each_with_index { |op, j|
    expect = ->got { raise TestFailure, "#{j} expected #{op['expected']} but got #{got}" if got != op['expected'] }

    case op['operation']
    when 'count'; expect[list.size]
    when 'toList'
      case mode
      when :fifo; expect[list]
      when :lifo; expect[list.reverse]
      else list.size <= 1 ? list : (raise "set toList mode for #{list}")
      end
    when 'peek'
      if op['expected'].is_a?(Integer)
        expect[list[-1]]
      else
        raise TestFailure, "peek on a non-empty list #{list} won't error" unless list.empty?
      end
    when 'pop'
      if op['expected'].is_a?(Integer)
        expect[list.pop]
      else
        raise TestFailure, "pop on a non-empty list #{list} won't error" unless list.empty?
      end
    when 'push'; list << op['value']
    when 'reverse'; list.reverse!
    else raise "unsupported #{op}"
    end
  }
end

cases = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))['cases'].flat_map { |cs| cs['cases'] }
not_reimplemented = cases.reject { |c| c['uuid'] == '70d747a1-2e84-4ebc-bc3f-dcbee6a05f6b' }

# Not the best fit for verify, since we just dispatch on operation and raise, accepting if we get to the end.
# However, this will change with the schema anyway, so we don't care.
verify(not_reimplemented, accept: ->(_, _) { true }, property: 'list') { |i, c|
  run_ops(i, mode: (c['comments'] || []).include?('toList LIFO') ? :lifo : (c['comments'] || []).include?('toList FIFO') ? :fifo : nil )
}
