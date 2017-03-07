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

verify(json['cases'], property: 'findFewestCoins') { |i, _|
  fewest_coins(i['target'], i['coins'])
}
