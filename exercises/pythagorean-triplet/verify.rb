require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'].map { |c| c.merge('expected' => c['expected'].sort) }, property: 'tripletsWithSum') { |i, _|
  n = i[?n]
  (1...(n / 3)).each_with_object([]) { |a, triplets|
    # c = n - a - b
    # a^2 + b^2 = c^2
    # a^2 + b^2 = n^2 - 2an - 2bn + a^2 + 2ab + b^2
    # 2bn - 2ab = n^2 - 2an
    # 2b(n - a) = n(n-2a)
    # b = n(n-2a) / 2(n-a)
    # b = (n(n-a) - an) / 2(n-a)
    b = n / 2 - a * n / (2 * (n - a))
    break triplets if a >= b
    c = n - a - b
    triplets << [a, b, c] if a * a + b * b == c * c
  }
}
