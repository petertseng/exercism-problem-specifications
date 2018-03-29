require_relative 'verify'

ANY_OLD_ANSWER = 819
P = ?p

class A < StandardError; end

def assert_one_at(arr, i)
  arr = arr.dup
  got = arr.delete_at(i)
  raise "Nope, #{arr} instead of 1 at #{i}" if got != 1 || !arr.all?(&:zero?)
end

def assert_pass(c, **kwargs)
  r = run([c], property: P, **kwargs) { yield }
  assert_one_at(r, 0)
end

def assert_fail(c, **kwargs)
  r = run([c], property: P, **kwargs) { yield }
  assert_one_at(r, 1)
end

def assert_error(c, **kwargs)
  r = run([c], property: P, **kwargs) { yield }
  assert_one_at(r, 2)
end

def test(**kwargs)
  normal_case = {
    'description' => 'normal',
    'property' => P,
    'input' => {},
    'expected' => ANY_OLD_ANSWER,
  }

  error_case = {
    'description' => 'error',
    'property' => P,
    'input' => {},
    'expected' => {'error' => 'hello'},
  }

  puts 'Passes when returning the right answer:'
  assert_pass(normal_case, **kwargs) { ANY_OLD_ANSWER }

  puts 'Fails when returning the wrong answer:'
  assert_fail(normal_case, **kwargs) { ANY_OLD_ANSWER + 100 }

  puts 'Fails when using TestFailure:'
  assert_fail(normal_case, **kwargs) { raise TestFailure, 'hello' }

  puts 'Errors when erroring unexpectedly:'
  assert_error(normal_case, **kwargs) { raise 'no' }

  puts 'Fails when not erroring even though it should:'
  assert_fail(error_case, **kwargs) { ANY_OLD_ANSWER }

  puts 'Fails when using TestFailure (error expected):'
  assert_fail(error_case, **kwargs) { raise TestFailure, 'hello' }

  puts 'Passes when erroring when it should:'
  assert_pass(error_case, **kwargs) { raise 'yes' }

  puts 'undefined method is acceptable for an error'
  assert_pass(error_case, **kwargs) { 5.nonexistent819 }

  puts 'Fails when not erroring even though it should (specific error):'
  assert_fail(error_case, error_class: A, **kwargs) { ANY_OLD_ANSWER }

  puts 'Passes when erroring with the right error when it should:'
  assert_pass(error_case, error_class: A, **kwargs) { raise A, 'hello' }

  puts 'Fails when using TestFailure (specific error):'
  assert_fail(error_case, error_class: A, **kwargs) { raise TestFailure, 'hello' }

  puts 'Errors when erroring with the wrong error:'
  assert_error(error_case, error_class: A, **kwargs) { raise 'hello' }
end

test
# NOTE that should_fail does NOT change any of these pass/fail/error classifications.
# It only changes their output and how they are interpreted by the runner.
test(should_fail: true)

puts 'yes'
