require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

CIRCLES = [
  {radius: 1, score: 10},
  {radius: 5, score: 5},
  {radius: 10, score: 1},
].map(&:freeze).freeze

verify(json['cases'], property: 'score') { |i, _|
  dist2 = i[?x] ** 2 + i[?y] ** 2

  relevant_circle = CIRCLES.find { |c| dist2 <= c[:radius] ** 2 }

  relevant_circle&.[](:score) || 0
}
