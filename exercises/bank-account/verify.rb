require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

bank = ->(acc, op) {
  assert_open = -> { raise "not open #{acc}" unless acc.is_a?(Integer) }
  assert_nonnegative = -> { raise "negative operand #{op}" if op['amount'] < 0 }
  case op['operation']
  when 'open'
    raise "already open #{acc}" if acc != :closed
    0
  when 'close'
    assert_open[]
    :closed
  when 'balance'
    assert_open[]
    acc
  when 'deposit'
    assert_open[]
    assert_nonnegative[]
    acc + op['amount']
  when 'withdraw'
    assert_open[]
    assert_nonnegative[]
    raise "#{op} overdraws #{acc}" if op['amount'] > acc
    acc - op['amount']
  when 'concurrent'
    op['operations'].reduce(acc, &bank)
  else raise "TODO: operation #{op}"
  end
}

verify(json['cases'], property: 'bankAccount') { |i, _|
  i['operations'].reduce(:closed, &bank)
}
