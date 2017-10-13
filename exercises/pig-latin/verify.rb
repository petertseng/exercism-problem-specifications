require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

vowel = /[aeiou]|^xr|^yt/

verify(json['cases'].flat_map { |c| c['cases'] }, property: 'translate') { |i, _|
  i['phrase'].split.map { |word|
    cut = case first_vowel = word =~ vowel
    when nil; word.index(?y)
    when 0; 0
    else
      first_vowel + (word[first_vowel - 1, 2] == 'qu' ? 1 : 0)
    end
    word[cut..-1] + word[0...cut] + 'ay'
  }.join(' ')
}
