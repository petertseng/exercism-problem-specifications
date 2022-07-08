require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

raise "There should be exactly three cases, not #{json['cases'].size}" if json['cases'].size != 3

def tri?(sides)
  a, b, c = sides.sort
  a + b > c
end

multi_verify(json['cases'][0]['cases'], property: 'equilateral', implementations: [
  {
    name: 'correct',
    f: ->(i, _) {
      sides = i['sides']
      tri?(sides) && sides.all? { |s| s == sides[0] }
    },
  },
  {
    name: 'only checks 2 shortest',
    should_fail: true,
    f: ->(i, _) {
      sides = i['sides']
      a, b, c = sides.sort
      tri?(sides) && a == b
    },
  },
  {
    name: 'only checks 2 longest',
    should_fail: true,
    f: ->(i, _) {
      sides = i['sides']
      a, b, c = sides.sort
      tri?(sides) && b == c
    },
  },
  {
    name: 'only checks 1 and 2',
    should_fail: true,
    f: ->(i, _) {
      sides = i['sides']
      a, b, c = sides
      tri?(sides) && a == b
    },
  },
  {
    name: 'only checks 2 and 3',
    should_fail: true,
    f: ->(i, _) {
      sides = i['sides']
      a, b, c = sides
      tri?(sides) && b == c
    },
  },
  {
    name: 'only checks 1 and 3',
    should_fail: true,
    f: ->(i, _) {
      sides = i['sides']
      a, b, c = sides
      tri?(sides) && a == c
    },
  },
])

multi_verify(json['cases'][1]['cases'], property: 'isosceles', implementations: [
  {
    name: 'correct',
    f: ->(i, _) {
      sides = i['sides']
      a, b, c = sides.sort
      # If eq can't be isos, check a != c
      tri?(sides) && (a == b || b == c)
    },
  },
  {
    name: 'reject equilaterals',
    should_fail: true,
    f: ->(i, _) {
      sides = i['sides']
      a, b, c = sides.sort
      tri?(sides) && (a == b || b == c) && a != c
    },
  },
])

multi_verify(json['cases'][2]['cases'], property: 'scalene', implementations: [
  {
    name: 'correct',
    f: ->(i, _) {
      sides = i['sides']
      a, b, c = sides.sort
      tri?(sides) && a != b && b != c
    }
  },
  {
    name: 'only checks longs != short',
    should_fail: true,
    f: ->(i, _) {
      sides = i['sides']
      a, b, c = sides.sort
      tri?(sides) && a != b && a != c
    }
  },
  {
    # https://github.com/exercism/problem-specifications/issues/2072
    name: 'only checks shorts != long',
    should_fail: true,
    f: ->(i, _) {
      sides = i['sides']
      a, b, c = sides.sort
      tri?(sides) && a != c && b != c
    }
  },
])
