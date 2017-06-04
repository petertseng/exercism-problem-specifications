require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'steps') { |i, _|
  x = i['number']
  raise 'positive only' if x <= 0
  0.step { |n|
    if x == 1
      break n
    elsif x.even?
      x /= 2
    else
      x *= 3
      x += 1
    end
  }
}
