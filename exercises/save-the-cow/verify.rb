require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'guess') { |i, _|
  word = i['word']
  letter_pos = word.each_char.with_index.with_object(Hash.new(0)) { |(c, i), h|
    h[c] |= (1 << i)
  }
  win = (1 << word.size) - 1
  remaining_failures = 9
  know = 0
  i['guesses'].each { |guess|
    raise 'you lost already' if remaining_failures < 0
    raise 'you won already' if know == win

    next remaining_failures -= 1 if letter_pos[guess] == 0

    know |= letter_pos[guess]
    letter_pos.delete(guess)
  }

  {
    'state' => remaining_failures < 0 ? 'Lose' : know == win ? 'Win' : 'Ongoing',
    'maskedWord' => word.each_char.with_index.map { |c, i| know[i] == 0 ? ?_ : c }.join,
    'remainingFailures' => remaining_failures.clamp(0..),
  }
}
