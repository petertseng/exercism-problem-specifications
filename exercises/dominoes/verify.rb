require 'json'
require_relative '../../verify'

def chain(dominoes)
  return [true, []] if dominoes.empty?
  first = dominoes.shift
  success, subchain = chain_with(dominoes, start_with: first.last, end_with: first.first)
  [success, subchain && ([first] + subchain).freeze]
end

# Make a chain that starts and ends with the specified values.
# Use every possible domino that can match `start_with` and recurse.
# `end_with` is just passed through to the very end and checked when there are no more dominoes.
def chain_with(dominoes, start_with:, end_with:)
  return [start_with == end_with, []] if dominoes.empty?

  dominoes.each_with_index { |d, i|
    if d.first == start_with
      target = d
    elsif d.last == start_with
      target = d.rotate
    else
      next
    end

    remaining_dominoes = dominoes.dup
    raise if d != remaining_dominoes.delete_at(i)

    success, subchain = chain_with(remaining_dominoes, start_with: target.last, end_with: end_with)
    return [true, ([target] + subchain).freeze] if success
  }

  [false, nil]
end

def assert_equal(a, b, message)
  raise TestFailure, "#{a} != #{b} #{message}" if a != b
end

def check(input, result)
  assert_equal(input.size, result.size, "#{input} => #{result} length mismatch")
  assert_equal(input.map(&:sort).sort, result.map(&:sort).sort, "#{input} => #{result} domino mismatch")
  result.zip(result.rotate).each_with_index { |((_a, b), (c, _d)), i|
    raise TestFailure, "#{input} => #{result} - bad chain #{b} != #{c} at #{i}" if b != c
  }
end

# Make sure that check raises when it should
should_raises = [
  # length both ways
  ->{ check([], [1]) },
  ->{ check([1], []) },
  # using the wrong dominoes
  ->{ check([[1, 1], [2, 2]], [[1, 2], [2, 1]]) },
  # adjacent dominoes don't have an equal number
  ->{ check([[1, 3], [2, 3], [3, 1]], [[1, 3], [2, 3], [3, 1]]) },
  # head and tail don't have an equal number
  ->{ check([[1, 3], [3, 3], [3, 2]], [[1, 3], [3, 3], [3, 2]]) },
]

should_raises.each_with_index { |should_raise, i|
  begin
    should_raise[]
  rescue TestFailure => e
    puts "#{i} raised #{e}, OK"
  else
    raise "#{i} didn't raise"
  end
}

puts

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

multi_verify(json['cases'], accept: ->(c, (can_chain, result)) {
  want = c['expected']
  # Extra paranoid that we do something wrong, so print
  input = c['input']['dominoes']
  want == can_chain && (!want || (
    begin
      check(input.dup, result)
    rescue TestFailure => e
      puts e
      false
    end
  ))
}, property: 'canChain', implementations: [
  {
    name: 'correct',
    f: ->(i, _) {
      chain(i['dominoes'].dup)
    }
  },
  {
    name: 'input',
    should_fail: true,
    f: -> (i, c) {
      [!!c['expected'], c['expected'] ? i['dominoes'].dup : nil]
    }
  },
  {
    name: 'always 1, 1',
    should_fail: true,
    f: -> (i, c) {
      [!!c['expected'], c['expected'] ? [[1, 1]] : nil]
    }
  },
  {
    name: 'always 1, 2',
    should_fail: true,
    f: -> (i, c) {
      [!!c['expected'], c['expected'] ? [[1, 2]] : nil]
    }
  },
  {
    name: 'always 1, 1 times length',
    should_fail: true,
    f: -> (i, c) {
      [!!c['expected'], c['expected'] ? [[1, 1]] * i['dominoes'].size : nil]
    }
  },
])
