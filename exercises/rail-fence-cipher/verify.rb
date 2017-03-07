require 'json'
require_relative '../../verify'

def transpose(letters, num_rails)
  rails = Array.new(num_rails) { [] }
  direction = 1
  rail = 0
  (0...letters).each { |i|
    rails[rail] << i
    rail += direction
    direction *= -1 if rail == num_rails - 1 || rail == 0
  }
  (0...letters).zip(rails.flatten).to_h
end

def encode(msg, rails)
  return msg if rails == 1
  transpose(msg.size, rails).map { |_, j| msg[j] }.join
end

def decode(msg, rails)
  return msg if rails == 1
  transpose(msg.size, rails).invert.sort.map { |_, j| msg[j] }.join
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

raise "There should be exactly two cases, not #{json['cases'].size}" if json['cases'].size != 2

verify(json['cases'][0]['cases'], property: 'encode') { |i, _|
  encode(i['msg'], i['rails'])
}

verify(json['cases'][1]['cases'], property: 'decode') { |i, _|
  decode(i['msg'], i['rails'])
}
