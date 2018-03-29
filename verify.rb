def by_property(cases, properties)
  h = cases.group_by { |c| c['property'] }
  raise "Invalid properties #{h.keys - properties} instead of #{properties}" if h.keys.sort != properties.sort
  h
end

# Use this class to distinguish between failing a test vs any other error.
# In should_fail mode, TestFailures are treated like any other failure
# (there must be at least one failure for should_fail to be accepted).
# In should_fail mode, all other errors are still rejected,
# to catch bugs in should_fail implementations.
class TestFailure < StandardError; end

module Colours refine String do
  def colour(c)
    "\e[#{c}m#{self}\e[0m"
  end

  def red; colour('1;31') end
  def green; colour('1;32') end
  def bold; colour('1') end
end end

using Colours

def run(
  cases, property:,
  should_fail: false,
  error: ->(c) { (exp = c['expected']).is_a?(Hash) && exp.has_key?('error') },
  error_class: StandardError,
  accept: ->(c, answer) { c['expected'] == answer }
)
  # In should_fail mode:
  # Passing test: No output (rather than output in green).
  # Failing test: Output in green (rather than red).
  #
  # Expected error: No output (rather than output in green)
  # Unexpected error: Output in red (we still don't want unexpected errors)
  #
  # No error, but should have had error: Output in green (rather than red)
  failed = 0
  passed = 0
  errored = 0
  fail_colour = should_fail ? '1;32' : '1;31'

  cases.each_with_index { |c, i|
    prefix = "#{i}. #{c['description']}"
    if property && c['property'] != property
      failed += 1
      puts "#{prefix}: Invalid property #{c['property']} instead of #{property}".colour(fail_colour)
      next
    end

    error_expected = error[c]

    begin
      answer = yield c['input'], c
    rescue TestFailure => e
      puts "#{prefix}: #{e}".colour(fail_colour)
      failed += 1
    rescue => e
      if error_expected && e.is_a?(error_class)
        puts "#{prefix}: Errored as expected: #{e}".green unless should_fail
        passed += 1
      else
        wanted = error_expected ? error_class.to_s : 'no error'
        puts "#{prefix}: Unwanted error in #{c['description']}, wanted #{wanted}".red
        errored += 1
        puts e.message
        puts "Backtrace:\n\t#{e.backtrace.join("\n\t")}"
      end
    else
      if error_expected
        puts "#{prefix}: Unexpectedly no error, instead got #{answer}".colour(fail_colour)
        failed += 1
      elsif !accept[c, answer]
        # TODO: expected isn't necessarily the right thing.
        expected = c['expected']
        puts "#{prefix}: Got #{answer} instead of #{expected}".colour(fail_colour)
        if answer.is_a?(Array) && expected.is_a?(Array) && !should_fail
          puts "Extraneous elements: #{answer - expected}"
          puts "Missing elements: #{expected - answer}"
        end
        failed += 1
      else
        puts prefix.green unless should_fail
        passed += 1
      end
    end
  }

  [passed, failed, errored]
end

def verify(*args, **kwargs, &block)
  puts "== verify #{kwargs[:property]} ==".bold

  passed, failed, errored = run(*args, **kwargs, &block)

  puts "#{passed} passed, #{failed} failed, #{errored} errored"

  if failed > 0 || errored > 0
    at_exit { raise "#{failed} failed, #{errored} errored in a test of #{kwargs[:property]}" }
  end
end

def multi_verify(*args, implementations:, **kwargs)
  implementations.each { |impl|
    should_fail = !!impl[:should_fail]
    puts "== #{'anti-' if should_fail}verify #{impl[:name]} #{kwargs[:property]} ==".bold

    _, failed, errored = run(*args, **kwargs, should_fail: should_fail, &impl[:f])

    actually_failed = failed > 0
    if errored > 0 || should_fail != actually_failed
      at_exit { raise "#{impl[:name]}: #{failed} failed, #{errored} errored in a test of #{kwargs[:property]}" }
    end
  }
end
