require 'json'
require_relative '../../verify'

# Wow, this verifies the description too!
ALLERGENS = File.readlines(File.join(__dir__, 'description.md')).grep(/^\* [a-z]+ \([\d]+\)$/).to_h { |line|
  [line[/[a-z]+/], line[/\d+/].to_i]
}.freeze

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

raise "Have #{json['cases'].size} cases, but expected #{ALLERGENS.size + 1}" if json['cases'].size != ALLERGENS.size + 1

json['cases'][0..-2].each { |c, _|
  verify(c['cases'], property: 'allergicTo') { |i, _|
    i['score'] & ALLERGENS[i['item']] != 0
  }
}

verify(json['cases'][-1]['cases'], property: 'list') { |i, _|
  ALLERGENS.select { |_, v| i['score'] & v != 0 }.keys
}
