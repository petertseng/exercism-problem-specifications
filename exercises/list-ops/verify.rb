require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

fs = {
  '(x) -> x modulo 2 == 1' => :odd?,
  '(x) -> x + 1' => :succ,
}.freeze

fold_fs = {
  '(x, y) -> x * y' => Hash.new(:*),
  '(x, y) -> x + y' => Hash.new(:+),
  '(x, y) -> x / y' => {
    # Old cases required Haskell-like notation:
    # foldl takes its accumulator first, foldr takes its accumulator last.
    'foldl' => :/,
    'foldr' => ->(a, x) { x / a },
  },
  '(acc, el) -> el * acc' => Hash.new(:*),
  '(acc, el) -> el + acc' => Hash.new(:+),
  # New cases do not use Haskell-like notation - they'll always pass accumulator first
  '(acc, el) -> el / acc' => Hash.new(->(a, x) { Rational(x, a) }),
}.each_value(&:freeze).freeze

props = {
  'append' => ->(c) { c['list1'] + c['list2'] },
  'concat' => ->(c) { c['lists'].flatten(1) },
  'filter' => ->(c) { c['list'].select(&fs.fetch(c['function'])) },
  'length' => ->(c) { c['list'].size },
  'map' => ->(c) { c['list'].map(&fs.fetch(c['function'])) },
  'foldl' => ->(c) { c['list'].reduce(c['initial'], &fold_fs.fetch(c['function'])['foldl']) },
  'foldr' => ->(c) { c['list'].reverse.reduce(c['initial'], &fold_fs.fetch(c['function'])['foldr']) },
  'reverse' => ->(c) { c['list'].reverse },
}.freeze

if json['cases'].size != props.size
  keys = props.keys
  [json['cases'].size, props.size].max.times { |n|
    puts '%12s / %12s' % [json.dig('cases', n, 'cases', 0, 'property'), keys[n]]
  }
  raise 'Length mismatch'
end

json['cases'].zip(props) { |cs, (prop, f)|
  verify(cs['cases'], property: prop) { |i, _| f[i] }
}

multi_verify(json['cases'][props.keys.index('concat')]['cases'], property: 'concat', implementations: [
  {
    # https://github.com/exercism/problem-specifications/pull/1240
    name: 'full flatten instead of concat',
    should_fail: true,
    f: ->(i, _) { i['lists'].flatten },
  },
])

[
  ['foldl', 'foldr'],
  ['foldr', 'foldl'],
].each { |a, b|
  cases = json['cases'][props.keys.index(a)]
  multi_verify(cases['cases'], property: a, implementations: [
    {
      name: "using #{a} for #{b}",
      should_fail: true,
      f: ->(i, _) { props.fetch(b)[i] },
    },
    {
      name: "using #{a} + reverse for #{b}",
      should_fail: true,
      f: ->(i, _) {
        begin
          props.fetch(b)[i.merge('list' => i['list'].reverse)]
        rescue ZeroDivisionError => e
          # That's fine, return it to fail the test as expected.
          # (Don't raise it since all exceptions are rejected)
          e
        end
      },
    },
  ])
}
