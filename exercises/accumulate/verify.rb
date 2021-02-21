require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

fs = {
  '(x) => x * x' => ->x { x * x },
  '(x) => reverse(x)' => :reverse,
  '(x) => upcase(x)' => :upcase,
  '(x) => accumulate(["1", "2", "3"], (y) => x + y))' => ->x { %w(1 2 3).map { |y| x + y } },
}.freeze

verify(json['cases'], property: 'accumulate') { |i, _|
  i['list'].map(&fs.fetch(i['accumulator']))
}
