require 'json'
require 'prime'
require_relative '../../verify'

def primes
  Enumerator.new do |y|
    y << 2
    y << 3
    nonprimes = Hash.new { |h, k| h[k] = [] }

    # now that we've done 2 and 3,
    # only possible primes are 6n-1 and 6n+1
    6.step(by: 6) { |multiple_of_six|
      [multiple_of_six - 1, multiple_of_six + 1].each { |candidate|
        unless nonprimes.has_key?(candidate)
          y << candidate
          # similarly, we only need to eliminate every 5th, 7th, 11th, 13th, etc. multiple.
          # we can avoid storing the other factor by simply storing one for 5 and one for 7.
          # this also means we can increase by 6 unconditionally instead of deciding between 2 and 4.
          nonprimes[candidate * 5] << candidate * 6
          nonprimes[candidate * 7] << candidate * 6
          next
        end

        nonprimes.delete(candidate).each { |prime_factor_times_six|
          nonprimes[candidate + prime_factor_times_six] << prime_factor_times_six
        }
      }
    }
  end
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

multi_verify(json['cases'], property: 'primes', implementations: [
  {
    name: 'stdlib',
    f: ->(i, _) {
      Prime.each(i['limit']).to_a
    },
  },
  {
    name: 'dynamic',
    f: ->(i, _) {
      primes.take_while { |n| n <= i['limit'] }
    },
  },
])
