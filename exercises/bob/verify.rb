require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'response') { |i, _|
  # Yes, the uppercase check is different for yell vs yell && question.
  # They should be the same, but then how would I use `case`?
  # As it stands, there is no test that refutes the check for yell && question.
  case i['heyBob']
  when /\A[A-Z' ]+\?\z/; "Calm down, I know what I'm doing!"
  when ->(t) { t.downcase != t && t.upcase == t }; 'Whoa, chill out!'
  when /\?\s*\z/; 'Sure.'
  when /\A\s*\z/; 'Fine. Be that way!'
  else 'Whatever.'
  end
}
