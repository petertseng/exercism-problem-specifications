require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'spiralMatrix') { |i, _|
  size = i['size']
  Array.new(size) { Array.new(size) }.tap { |a|
    len = size
    place = [0, -1]
    dir = [0, 1]
    n = 0
    # right N times,
    # down N-1 times,
    # left N-1 times,
    # up N-2 times,
    # right N-2 times,
    # ...
    # right (odd)/left (even) 1 time
    while len > 0
      len.times {
        place = place.zip(dir).map(&:sum)
        a[place[0]][place[1]] = (n += 1)
      }
      dir.reverse!
      if dir[0] == 0
        dir.map!(&:-@)
      else
        len -= 1
      end
    end
  }
}
