require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

CIRCLES = [
  {radius: 1, score: 10},
  {radius: 5, score: 5},
  {radius: 10, score: 1},
].map(&:freeze).freeze

find_circles = [
  ['correct', ->(_, _, d2) { CIRCLES.find { |c| d2 <= c[:radius] ** 2 } }],
  ['equal not inside', ->(_, _, d2) { CIRCLES.find { |c| d2 < c[:radius] ** 2 } }],
  ['rev', ->(_, _, d2) { CIRCLES.reverse.find { |c| d2 <= c[:radius] ** 2 } }],
  ['x only', ->(x, _, _) { CIRCLES.find { |c| 2 * x ** 2 <= c[:radius] ** 2 } }],
  ['y only', ->(_, y, _) { CIRCLES.find { |c| 2 * y ** 2 <= c[:radius] ** 2 } }],
  ['abs', ->(x, y, _) { CIRCLES.find { |c| x.abs + y.abs <= c[:radius] } }],
  ['squares', ->(x, y, _) { CIRCLES.find { |c| x <= c[:radius] && y <= c[:radius] } }],
]

multi_verify(json['cases'], property: 'score', implementations: find_circles.map { |name, fc|
  {
    name: name,
    should_fail: name != 'correct',
    f: ->(i, _) {
      relevant_circle = fc[x = i[?x], y = i[?y], x ** 2 + y ** 2]
      relevant_circle&.[](:score) || 0
    }
  }
})
