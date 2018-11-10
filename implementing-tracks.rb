require 'json'

topics = ARGV.delete('-t') || ARGV.delete('--topics')

# Allow tab-completion of exercises/<exercise-slug>
slug = ARGV[0].split(?/).last

implementing_tracks = Dir.glob("#{__dir__}/configs/*.json").map { |f|
  json = JSON.parse(File.read(f))
  exercise = (json['exercises'] || []).find { |e| e['slug'] == slug }
  exercise && [File.basename(f, '.json'), exercise]
}.compact.sort.to_h

longest_track = implementing_tracks.keys.map(&:size).max
longest_topic = topics ? implementing_tracks.values.map { |e| e['topics']&.map(&:size)&.max || 0 }.max : 0

line1 = "%#{longest_track}s %2d %#{longest_topic}s %s"
line2 = (' ' * (longest_track + 4)) + "%#{longest_topic}s"

def uri(track, slug)
  "https://github.com/exercism/#{track}/tree/master/exercises/#{slug}"
end

implementing_tracks.each { |track, ex|
  puts line1 % [track, ex['difficulty'], (topics ? ex.dig('topics', 0) : ''), uri(track, slug)]
  ex['topics']&.drop(1)&.each { |topic| puts line2 % topic } if topics
}
