require 'json'
require_relative '../../verify'

def verify_schema(h)
  h.each { |k, v|
    raise "Nope, #{k} has multiple schemas: #{v}" if v.size > 1
    keys, times = v.first
    puts '%22s: %2d times, keys %s' % [k, times, keys]
  }
end

cases = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))['cases']

puts 'Cells:'
verify_schema(cases.each_with_object(Hash.new { |h, k| h[k] = Hash.new(0) }) { |c, h|
  c['input']['cells'].each { |cell|
    ks = cell.keys
    raise "#{cell} has no name" unless ks.delete('name')
    raise "#{cell} has no type" unless ks.delete('type')
    h[cell['type']][ks] += 1
  }
})

puts 'Operations:'
verify_schema(cases.each_with_object(Hash.new { |h, k| h[k] = Hash.new(0) }) { |c, h|
  c['input']['operations'].each { |op|
    ks = op.keys
    raise "#{op} has no type" unless ks.delete('type')
    h[op['type']][ks] += 1
  }
})

class Cell
  attr_reader :value

  # TODO: should not be called on a ComputeCell.

  def initialize(initial_value)
    @value = initial_value
    @dependencies = []
  end

  protected

  attr_reader :dependencies
end

class InputCell < Cell
  def initialize(initial_value, broken: false)
    super(initial_value)
    @broken = broken
  end

  def value=(new_value)
    @value = new_value
    if @broken
      @dependencies.each { |d|
        d.update_dependencies
        d.fire_callbacks
      }
    else
      @dependencies.each(&:update_dependencies)
      @dependencies.each(&:fire_callbacks)
    end
  end
end

class ComputeCell < Cell
  def initialize(*inputs, &compute)
    new_value = -> { compute.call(*inputs.map(&:value)) }
    super(new_value.call)
    @last_value = @value
    @new_value = new_value
    inputs.each { |i| i.dependencies << self }
    @callbacks = {}
    @callbacks_issued = 0
  end

  def add_callback(&block)
    @callbacks_issued += 1
    @callbacks[@callbacks_issued] = block
    @callbacks_issued
  end

  def remove_callback(id)
    @callbacks.delete(id)
  end

  # TODO: Would like for only InputCells and ComputeCells to call these two.

  def update_dependencies
    new_value = @new_value.call
    return if new_value == @value
    @value = new_value
    @dependencies.each(&:update_dependencies)
  end

  def fire_callbacks
    return if @value == @last_value
    @callbacks.each_value { |c| c.call(@value) }
    @last_value = @value
    @dependencies.each(&:fire_callbacks)
  end
end

def cells(cell_specs, broken: false)
  cell_specs.each_with_object({}) { |cell_spec, acc_cells|
    acc_cells[cell_spec.fetch('name')] = case cell_spec['type']
    when 'input'
      InputCell.new(cell_spec.fetch('initial_value'), broken: broken)
    when 'compute'
      inputs = cell_spec['inputs'].map { |input| acc_cells.fetch(input) }
      case (f = cell_spec['compute_function'])
      when /^inputs\[0\] \+ (\d+)$/
        val = $1.to_i
        ComputeCell.new(*inputs) { |v| v + val.to_i }
      when /^inputs\[0\] - (\d+)$/
        val = $1.to_i
        ComputeCell.new(*inputs) { |v| v - val.to_i }
      when /^inputs\[0\] \* (\d+)$/
        val = $1.to_i
        ComputeCell.new(*inputs) { |v| v * val.to_i }
      when /^if inputs\[0\] < (\d+) then (\d+) else (\d+)$/
        cmp = $1.to_i
        t = $2.to_i
        f = $3.to_i
        ComputeCell.new(*inputs) { |v| v < cmp ? t : f }
      when /^inputs\[0\] \+ inputs\[1\]$/
        ComputeCell.new(*inputs) { |x, y| x + y }
      when /^inputs\[0\] \+ inputs\[1\] \* (\d+)$/
        val = $1.to_i
        ComputeCell.new(*inputs) { |x, y| x + y * val }
      when /^inputs\[0\] - inputs\[1\]$/
        ComputeCell.new(*inputs) { |x, y| x - y }
      when /^inputs\[0\] \* inputs\[1\]$/
        ComputeCell.new(*inputs) { |x, y| x * y }
      else raise "unknown compute function #{f}"
      end
    else raise "unknown cell type #{cell_spec['type']}"
    end
  }
end

def run_ops(ops, cells)
  callbacks = {}

  ops.each { |op|
    case op['type']
    when 'expect_cell_value'
      cell = cells[op['cell']]
      raise TestFailure, "cell #{op['cell']} had #{cell.value} instead of #{op['value']}" if cell.value != op['value']
    when 'set_value'
      cells[op['cell']].value = op['value']
    when 'add_callback'
      name = op.fetch('name')
      vals = []
      callbacks[name] = {
        id: cells[op['cell']].add_callback { |v| vals << v },
        vals: vals,
      }
    when 'expect_callback_values'
      observed = callbacks[op['callback']][:vals]
      raise TestFailure, "callback #{op['callback']} had #{observed} instead of #{op['values']}" if observed != op['values']
      observed.clear
    when 'remove_callback'
      cells[op['cell']].remove_callback(callbacks[op['name']][:id])
    else raise "Unknown op #{op['type']}"
    end
  }
end

# Not the best fit for verify, since we just dispatch on operation and raise, accepting if we get to the end.
# However, this will change with the schema anyway, so we don't care.
multi_verify(cases, accept: ->(_, _) { true }, property: 'react', implementations: [false, true].map { |broken| {
  name: broken ? 'broken' : 'correct',
  should_fail: broken,
  f: ->(i, _) {
    cells = cells(i['cells'], broken: broken)
    run_ops(i['operations'], cells)
  }
}})
