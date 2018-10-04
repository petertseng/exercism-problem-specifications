require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

multi_verify(json['cases'], property: 'sum', implementations: [
  {
    name: 'correct',
    f: ->(i, _) {
      factors = i['factors'].reject(&:zero?)
      limit = i['limit']
      (1...limit).select { |n|
        factors.any? { |f| n % f == 0 }
      }.sum
    },
  },
  {
    name: 'inclusion-exclusion principle',
    f: ->(i, _) {
      factors = i['factors']
      signed_factors = (1..factors.size).flat_map { |n|
        # Even terms are subtracted, so 0 -> -1.
        # Odd terms are added, so 1 -> 1.
        sign = 2 * (n % 2) - 1
        factors.combination(n).map { |n_factors|
          n_factors.reduce(1) { |a, b| a.lcm(b) } * sign
        }
      }.freeze
      limit = i['limit']

      signed_factors.sum { |n|
        # how many times does it fit?
        n_terms = n == 0 ? 0 : (limit - 1) / n.abs
        n * n_terms * (n_terms + 1) / 2
      }
    },
  },
  {
    # https://github.com/exercism/problem-specifications/pull/1368
    name: 'inclusion-exclusion principle but broken for > 3',
    should_fail: true,
    f: ->(i, _) {
      factors = i['factors']
      signed_factors = (1..factors.size).flat_map { |n|
        # Even terms are subtracted, so 0 -> -1.
        # Odd terms are added, so 1 -> 1.
        sign = n > 3 ? 1000 : 2 * (n % 2) - 1
        factors.combination(n).map { |n_factors|
          n_factors.reduce(1) { |a, b| a.lcm(b) } * sign
        }
      }.freeze
      limit = i['limit']

      signed_factors.sum { |n|
        # how many times does it fit?
        n_terms = n == 0 ? 0 : (limit - 1) / n.abs
        n * n_terms * (n_terms + 1) / 2
      }
    },
  },
  {
    name: 'double-counts numbers',
    should_fail: true,
    f: ->(i, _) {
      factors = i['factors'].reject(&:zero?)
      limit = i['limit']
      factors.sum { |factor|
        (1...limit).select { |n|
          n % factor == 0
        }.sum
      }
    },
  },
])
