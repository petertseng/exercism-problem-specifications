require 'json'
require 'time'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

DAY = 86400

verify(json['cases'], property: 'deliveryDate') { |i, _|
  meeting = Time.parse(i['meetingStart'])
  case i['description']
  when 'NOW'; meeting + 7200
  when 'ASAP'
    if meeting.hour < 13
      Time.new(meeting.year, meeting.month, meeting.day, 17)
    else
      Time.new(meeting.year, meeting.month, meeting.day, 13) + DAY
    end
  when 'EOW'
    plus_days, hour = case meeting.wday
    when 1; [4, 17]
    when 2; [3, 17]
    when 3; [2, 17]
    when 4; [3, 20]
    when 5; [2, 20]
    else raise "#{meeting} weekend meeting"
    end
    Time.new(meeting.year, meeting.month, meeting.day, hour) + DAY * plus_days
  when /\A\d+M\z/
    m = Integer(i['description'][..-2])
    Enumerator.produce(Time.new(meeting.year + (meeting.month < m ? 0 : 1), m, 1, 8)) { |d| d + DAY }.find { |d| !d.saturday? && !d.sunday? }
  when /\AQ\d\z/
    q = Integer(i['description'][1])
    m = 3 * q
    d = {3 => 31, 6 => 30, 9 => 30, 12 => 31}.fetch(m)
    Enumerator.produce(Time.new(meeting.year + (meeting.month <= m ? 0 : 1), m, d, 8)) { |d| d - DAY }.find { |d| !d.saturday? && !d.sunday? }
  end.strftime('%FT%T')
}
