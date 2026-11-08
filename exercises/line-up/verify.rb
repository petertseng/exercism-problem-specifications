require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

def ord(n)
  case [n % 100, n % 10]
  in [11, _]; :th
  in [12, _]; :th
  in [13, _]; :th
  in [_, 1]; :st
  in [_, 2]; :nd
  in [_, 3]; :rd
  else :th
  end
end

verify(json['cases'], property: 'format') { |i, _|
  "#{i['name']}, you are the #{i['number']}#{ord(i['number'])} customer we serve today. Thank you!"
}
