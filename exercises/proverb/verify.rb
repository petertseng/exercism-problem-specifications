require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'recite') { |i, _|
  xs = i['strings']
  (xs.each_cons(2).map { |a, b|
    "For want of a #{a} the #{b} was lost."
  } + [xs[0] && "And all for the want of a #{xs[0]}."]).compact
}
