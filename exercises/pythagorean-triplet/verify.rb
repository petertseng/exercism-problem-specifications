require 'json'
require 'timeout'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

require 'set'

multi_verify(json['cases'].map { |c| c.merge('expected' => c['expected'].sort) }, property: 'tripletsWithSum', implementations: [
  {
    name: 'correct',
    f: ->(i, _) {
      n = i[?n]
      (1...(n / 3)).each_with_object([]) { |a, triplets|
        # c = n - a - b
        # a^2 + b^2 = c^2
        # a^2 + b^2 = n^2 - 2an - 2bn + a^2 + 2ab + b^2
        # 2bn - 2ab = n^2 - 2an
        # 2b(n - a) = n(n-2a)
        # b = n(n-2a) / 2(n-a)
        # b = (n(n-a) - an) / 2(n-a)
        # b = n(n-a) / 2(n-a) - an / 2(n-a)
        #
        # Note that this implies (among other things) that odd n will never produce any triplets.
        b = n / 2 - a * n / (2 * (n - a))
        break triplets if a >= b
        c = n - a - b
        triplets << [a, b, c] if a * a + b * b == c * c
      }
    },
  },
  {
    name: 'quadratic (0.1s timeout)',
    should_fail: true,
    f: ->(i, _) {
      # I wanted to see if any triplets at all had been found in the time,
      # but that was a silly idea.
      # Obviously none were found because it needs to go through all values of b for a = 1 first.
      triplets = []

      # switch to true if just wanting to see how long it takes
      report = false
      tstart = Time.now
      (Timeout.timeout(report ? 60 : 0.1) {
        n = i[?n]
        (1...(n / 3)).each_with_object(triplets) { |a, triplets|
          bmax = (n - a) / 2
          ((a + 1)..bmax).each { |b|
            c = n - a - b
            if a * a + b * b == c * c
              triplets << [a, b, c]
              break
            end
          }
        }
      }).tap {
        elapsed = Time.now - tstart
        puts "#{i[?n]} took #{elapsed}" if elapsed > 0.1
      } rescue (triplets << :timeout)
    },
  },
])
