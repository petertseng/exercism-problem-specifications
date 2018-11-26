require 'json'

common_exercises = Dir.glob("#{__dir__}/exercises/*/").map { |d| File.basename(d) }.freeze

tracks = Dir.glob("#{__dir__}/configs/*.json").map { |f|
  j = JSON.parse(File.read(f))
  exs = (j['exercises'] || []).reject { |e| e['deprecated'] }.map { |e| e['slug'] }
  [File.basename(f, '.json'), exs]
}.to_h

track_specific_repeats = Hash.new { |h, k| h[k] = [] }

tracks.each { |track, exs|
  track_specifics = exs - common_exercises
  next if track_specifics.empty?
  puts "#{track}: #{track_specifics}"
  track_specifics.each { |e|
    track_specific_repeats[e] << track
  }
}

puts 'REPEATS: '
track_specific_repeats.each { |ex, tracks_with|
  next if tracks_with.size <= 1
  puts "#{ex}: #{tracks_with}"
}
