require 'date'
require 'json'
require_relative '../../verify'

class Meetup
  ORDINAL_INDEX = {
    first: 0,
    second: 1,
    third: 2,
    fourth: 3,
    last: -1,
  }.freeze

  def self.each_day_of_month(year, month)
    Enumerator.new { |e|
      e << (date = Date.new(year, month, 1))
      e << date until (date = date.next_day).day == 1
    }
  end

  def initialize(month:, year:)
    @days = self.class.each_day_of_month(year, month).group_by { |day|
      Date::DAYNAMES[day.wday].downcase.to_sym
    }.each_value(&:freeze).freeze
  end

  def day(day_of_week, nth)
    return @days[day_of_week].find { |d| 13 <= d.day && d.day <= 19 } if nth == :teenth
    @days[day_of_week][ORDINAL_INDEX[nth]]
  end
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'meetup') { |i, _|
  Meetup.new(year: i['year'], month: i['month']).day(i['dayofweek'].downcase.to_sym, i['week'].to_sym).strftime('%Y-%m-%d')
}
