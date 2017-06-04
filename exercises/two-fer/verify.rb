require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'twoFer') { |i, _|
  "One for #{i['name'] || 'you'}, one for me."
}
