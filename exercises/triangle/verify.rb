require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

raise "There should be exactly three cases, not #{json['cases'].size}" if json['cases'].size != 3

def tri?(sides)
  a, b, c = sides.sort
  a + b > c
end

verify(json['cases'][0]['cases'], property: 'equilateral') { |i, _|
  sides = i['sides']
  tri?(sides) && sides.all? { |s| s == sides[0] }
}

verify(json['cases'][1]['cases'], property: 'isosceles') { |i, _|
  sides = i['sides']
  a, b, c = sides.sort
  # If eq can't be isos, check a != c
  tri?(sides) && (a == b || b == c)
}

verify(json['cases'][2]['cases'], property: 'scalene') { |i, _|
  sides = i['sides']
  a, b, c = sides.sort
  tri?(sides) && a != b && b != c
}
