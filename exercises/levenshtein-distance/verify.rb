require 'json'
require_relative '../../verify'

# https://web.archive.org/web/20180612143641/https://bitbucket.org/clearer/iosifovich/
def lev_dist(shorter, longer)
  shorter, longer = [longer, shorter] if shorter.size > longer.size
  left = 0
  right = -1
  left += 1 while shorter[left] &.== longer[left]
  right -= 1 while left - right <= shorter.size && shorter[right] == longer[right]

  buf = Array.new(shorter.size + 2 - left + right, 0)
  #puts "compare #{left} to #{right}: #{shorter[left..right]} vs #{longer[left..right]} (#{buf.size})"

  (left..(longer.size + right)).each { |i|
    clong = longer[i]
    tmp = buf[0]
    buf[0] += 1

    (1...buf.size).each { |j|
      cshort = shorter[left + j - 1]
      r = buf[j]
      buf[j] = [
        r + 1,
        buf[j - 1] + 1,
        tmp + (clong == cshort ? 0 : 1),
      ].min
      tmp = r
    }
  }

  buf[-1]
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'distance') { |i, _|
  lev_dist(i['from'], i['to'])
}
