def by_property(cases, properties)
  h = cases.group_by { |c| c['property'] }
  raise "Invalid properties #{h.keys - properties} instead of #{properties}" if h.keys.sort != properties.sort
  h
end

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
  error: ->(c) { (exp = c['expected']).is_a?(Hash) && exp.has_key?('error') },
  error_class: StandardError,
  accept: ->(c, answer) { c['expected'] == answer }
)
  failed = 0
  passed = 0

  cases.each_with_index { |c, i|
    prefix = "#{i}. #{c['description']}"
    if property && c['property'] != property
      failed += 1
      puts "#{prefix}: Invalid property #{c['property']} instead of #{property}".red
      next
    end

    error_expected = error[c]

    begin
      answer = yield c['input'], c
    rescue => e
      if error_expected && e.is_a?(error_class)
        puts "#{prefix}: Errored as expected: #{e}".green
        passed += 1
      else
        wanted = error_expected ? error_class.to_s : 'no error'
        puts "#{prefix}: Unwanted error in #{c['description']}, wanted #{wanted}".red
        failed += 1
        puts e.message
        puts "Backtrace:\n\t#{e.backtrace.join("\n\t")}"
      end
    else
      if error_expected
        puts "#{prefix}: Unexpectedly no error, instead got #{answer}".red
        failed += 1
      elsif !accept[c, answer]
        # TODO: expected isn't necessarily the right thing.
        expected = c['expected']
        puts "#{prefix}: Got #{answer} instead of #{expected}".red
        if answer.is_a?(Array) && expected.is_a?(Array)
          puts "Extraneous elements: #{answer - expected}"
          puts "Missing elements: #{expected - answer}"
        end
        failed += 1
      else
        puts prefix.green
        passed += 1
      end
    end
  }

  [passed, failed]
end

def verify(*args, **kwargs, &block)
  puts "== verify #{kwargs[:property]} ==".bold

  passed, failed = run(*args, **kwargs, &block)

  puts "#{passed} passed, #{failed} failed"

  raise "#{failed} failed" if failed > 0
end
