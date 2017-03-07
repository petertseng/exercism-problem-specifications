require 'json'
require_relative '../../verify'

OPS = {
  'plus'          => :+.to_proc,
  'minus'         => :-.to_proc,
  'multiplied by' => :*.to_proc,
  'divided by'    => :/.to_proc,
}.freeze

def parse(text)
  raise ArgumentError, "Not a question #{text}" unless text.end_with?(??)
  ops = text[0..-2].split(/(?<=[\d]) /)
  *question, value = ops.shift.split
  raise ArgumentError, "Unknown question #{text}" if question != ['What', 'is']

  ops.reduce(value.to_i) { |acc, op|
    *operator, operand = op.split
    f = OPS[operator.join(' ')] or raise ArgumentError, "Unknown op #{operator}"
    f[acc, Integer(operand)]
  }
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'answer') { |i, _|
  parse(i['question'])
}
