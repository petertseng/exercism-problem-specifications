require 'json'

topics = ARGV.delete('-t') || ARGV.delete('--topics')

# Allow tab-completion of exercises/<exercise-slug>
slug = ARGV[0].split(?/).last

def depth(exercises, slug)
  exercises.select { |ex| ex['core'] }.index { |ex| ex['slug'] == slug }
end

implementing_tracks = Dir.glob("#{__dir__}/configs/*.json").map { |f|
  json = JSON.parse(File.read(f))
  next unless (exercises = json['exercises'])
  next unless (exercise = exercises.find { |ex| ex['slug'] == slug })

  # https://github.com/exercism/website/blob/master/app/services/git/sync_track.rb
  # rules here for respect_core (any exercise is marked as core)
  if exercises.any? { |ex| ex['core'] }
    if exercise['core']
      depth = depth(exercises, exercise['slug'])
      type = :core
    elsif exercise['unlocked_by']
      depth = depth(exercises, exercise['unlocked_by'])
      type = :side
    else
      depth = 0
      type = :free
    end
  else
    idx = exercises.index(exercise)
    # first eleven (0..10 has 11 elements) exercises are cores.
    core = idx <= 10
    type = core ? :core : :free
    depth = core ? idx : 0
  end

  [File.basename(f, '.json'), exercise.merge('depth' => depth, 'type' => type)]
}.compact.sort.to_h

longest_track = implementing_tracks.keys.map(&:size).max
longest_topic = topics ? implementing_tracks.values.map { |e| e['topics']&.map(&:size)&.max || 0 }.max : 0

line1 = "%#{longest_track}s %2d %4s %2d %#{longest_topic}s %s"
line2 = (' ' * (longest_track + 12)) + "%#{longest_topic}s"

def uri(track, slug)
  "https://github.com/exercism/#{track}/tree/master/exercises/#{slug}"
end

implementing_tracks.each { |track, ex|
  puts line1 % [track, ex['difficulty'], ex['type'], ex['depth'], (topics ? ex.dig('topics', 0) : ''), uri(track, slug)]
  ex['topics']&.drop(1)&.each { |topic| puts line2 % topic } if topics
}
