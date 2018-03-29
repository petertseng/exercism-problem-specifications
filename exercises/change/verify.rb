require 'json'
require_relative '../../verify'

def fewest_coins(target, coins)
  raise 'negative' if target < 0

  best = Array.new(target + 1)
  best[0] = []

  coins.sort.reverse.each { |coin|
    (coin..target).each { |subtarget|
      next unless (best_without = best[subtarget - coin])
      next if best[subtarget]&.size &.<= best_without.size + 1
      best[subtarget] = [coin] + best_without
    }
  }

  # TODO: I might argue that this should not be an exception (return nil instead), but not important
  best[target]&.sort or raise 'impossible'
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

multi_verify(json['cases'], property: 'findFewestCoins', implementations: [
  {
    name: 'correct',
    f: -> (i, _) {
      fewest_coins(i['target'], i['coins'])
    },
  },
  {
    name: 'greedy',
    should_fail: true,
    f: -> (i, c) {
      remainder = i['target']
      coins = []
      i['coins'].sort.reverse_each { |coin|
        while remainder >= coin
          remainder -= coin
          coins << coin
        end
      }

      if coins.sum == i['target']
        coins.sort
      elsif c['expected'].is_a?(Array)
        nil
      else
        raise 'fail as expected'
      end
    },
  },
  {
    # https://github.com/exercism/problem-specifications/pull/882
    name: 'greedy but careful',
    should_fail: true,
    f: -> (i, c) {
      best_coins = [0] * (i['target'] + 1)
      smallest_coin = i['coins'].min

      # This solution chooses the smallest N coins,
      # knowing that large coins may lead to wrong solutions.
      # Of the coins selected, it starts from larger coins,
      # but ensures the solution remains still possible.
      #
      # To defeat it, craft a case where:
      # At the point where you must stop using some coin C,
      # the remainer still exceeds C + the smallest coin.
      (1..i['coins'].size).each { |n|
        remainder = i['target']
        my_coins = []
        i['coins'].sort.first(n).reverse_each { |coin|
          while remainder >= coin && (remainder - coin == 0 || remainder - coin >= smallest_coin)
            remainder -= coin
            my_coins << coin
          end
        }
        best_coins = my_coins if remainder == 0 && best_coins.size > my_coins.size
      }

      if best_coins.sum == i['target']
        best_coins.sort
      elsif c['expected'].is_a?(Array)
        nil
      else
        raise 'fail as expected'
      end
    },
  },
])
