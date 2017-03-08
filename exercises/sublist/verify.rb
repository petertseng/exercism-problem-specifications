require 'json'
require_relative '../../verify'

module Sublist refine Array do
  # https://en.wikipedia.org/wiki/Knuth%E2%80%93Morris%E2%80%93Pratt_algorithm
  def sublist_index(needle)
    return 0 if needle.empty?

    table = needle.partial_match_table

    match_begin = 0
    match_index = 0

    while (hay_at = self[match_begin + match_index])
      if needle[match_index] == hay_at
        return match_begin if match_index == needle.size - 1
        match_index += 1
      elsif (new_index = table[match_index]) && new_index >= 0
        match_begin += match_index - new_index
        match_index = new_index
      else
        match_begin += 1
        match_index = 0
      end
    end

    nil
  end

  def partial_match_table
    table = Array.new(size, 0)

    table[0] = nil unless empty?

    pos = 2
    candidate = 0

    while pos < size
      if self[pos - 1] == self[candidate]
        table[pos] = candidate + 1
        candidate += 1
        pos += 1
      elsif (new_candidate = table[candidate])
        candidate = new_candidate
      else
        table[pos] = 0
        pos += 1
      end
    end

    table
  end
end end

using Sublist

def rel(l1, l2)
  t, if_t = [
    [->{ l1 == l2 }, :equal],
    [->{ l1.sublist_index(l2) }, :superlist],
    [->{ l2.sublist_index(l1) }, :sublist],
  ][l1.size <=> l2.size]

  t[] ? if_t : :unequal
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'sublist') { |i, _|
  rel(i['listOne'], i['listTwo']).to_s
}
