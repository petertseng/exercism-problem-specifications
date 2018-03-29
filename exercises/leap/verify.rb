require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

multi_verify(json['cases'], property: 'leapYear', implementations: [
  {
    name: 'correct',
    f: ->(i, _) {
      div_by = ->(n) { i['year'] % n == 0 }
      div_by[4] && !div_by[100] || div_by[400]
    },
  },
  {
    # https://github.com/exercism/problem-specifications/pull/971
    name: 'mod 100 == mod 400',
    should_fail: true,
    f: ->(i, _) {
      div_by = ->(n) { i['year'] % n == 0 }
      div_by[4] && i['year'] % 100 == i['year'] % 400
    },
  },
])

def impl_good?(cs)
  cs.all? { |c| yield(c['input']['year']) == c['expected'] }
end

range_to_refute = (0..3000)
LEAP = range_to_refute.to_h { |y| [y, y % 4 == 0 && y % 100 != 0 || y % 400 == 0] }

def refute(impl)
  LEAP.select { |year, leap|
    year != 0 && impl[year] != leap
  }.keys
end

# N is the parameter that describes the function
# the Proc in each tuple is the leap? function taking a year.
# We're pretty much trying to find a covering set.
#
# improperly_passing: Array[Tuple[N, Proc[Y => Bool]]]
# assumed to be sorted in increasing N order.
#
# Returns
def refuting_sets(improperly_passing)
  # Strategy: Take smallest improperly passing implementation,
  # find all its refutations, take all the ones that refute the most others,
  # recurse, excluding the other impls that have now also been refuted.
  (_, impl1), *rest = improperly_passing
  refutations = refute(impl1)

  refuted_by = refutations.group_by { |ref| rest.select { |_, impl| impl[ref] != LEAP[ref] } }
  refute_by_count = refuted_by.group_by { |k, v| k.size }
  # best_refutes is an array of (refuted_impls, refuting years) tuples
  best_refutes = refute_by_count[refute_by_count.keys.max]
  subsolns = best_refutes.flat_map { |impls, years|
    remaining = rest - impls
    if remaining.empty?
      # I don't have to use a hash,
      # but I was having a hard time understanding the output without it :)
      [{
        size: 1,
        years: [years],
      }]
    else
      refuting_sets(remaining).map { |subsoln| {
        size: subsoln[:size] + 1,
        years: subsoln[:years] + [years],
      }}
    end
  }
  min_size = subsolns.map { |s| s[:size] }.min
  subsolns.select { |s| s[:size] == min_size }
end

max_year_in_cases = json['cases'].map { |c| c['input']['year'] }.max
check_impl_class = ->(description, impl_for_n, ok = []) {
  impls = (1..max_year_in_cases).map { |n|
    [n, impl_for_n[n]]
  }
  improperly_passing = impls.select { |n, impl|
    !ok.include?(n) && impl_good?(json['cases'], &impl)
  }
  break if improperly_passing.empty?

  sets = refuting_sets(improperly_passing)

  puts "#{description}: #{improperly_passing.map(&:first)}"
  if sets.first[:size] == 1
    raise 'Should only have size 1 as well???' unless sets.size == 1
    puts "Refute with any of #{sets.first[:years][0]}"
  else
    puts 'Refute with:'
    sets.each_with_index { |subset, i|
      puts "possibility #{i}:"
      subset[:years].each { |years|
        puts "    one of #{years}"
      }
    }
  end
}

# inspired by https://github.com/exercism/problem-specifications/pull/955 (16)
check_impl_class['Only divisibility by N', ->n { ->y { y % n == 0 } }]
check_impl_class['Only 4 and not N',       ->n { ->y { y % 4 == 0 && y % n != 0 } }]
check_impl_class['Only N and not 100',     ->n { ->y { y % n == 0 && y % 100 != 0 } }]
check_impl_class['Replaced 4 with N',      ->n { ->y { y % n == 0 && y % 100 != 0 || y % 400 == 0 } }, [4]]
check_impl_class['Replaced 100 with N',    ->n { ->y { y % 4 == 0 && y % n != 0   || y % 400 == 0 } }, [25, 50, 100]]
check_impl_class['Replaced 400 with N',    ->n { ->y { y % 4 == 0 && y % 100 != 0 || y % n == 0 } }, [16, 80, 400]]

# I'm not going to make these have exit status 1 since I generally don't care,
# but they're interesting to look at from time to time.
