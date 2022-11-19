require 'json'
require 'open3'

def set(exercise, old_h, old_k, new_v, nil_deletes: false, yes: false)
  return false if new_v.nil? && !nil_deletes
  return false if old_h[old_k] == new_v

  if yes
    if new_v.nil? && nil_deletes
      old_h.delete(old_k)
    else
      old_h[old_k] = new_v
    end
  else
    puts "#{exercise} #{old_k} #{old_h[old_k]} -> #{new_v}"
  end
  true
end

def write_json(file, json)
  # Too bad, pretty_generate doesn't format empty arrays how we want.
  # File.puts(file, JSON.pretty_generate(json))

  out, err = Open3.capture3('jq', '.', stdin_data: JSON.generate(json))
  raise "err #{err}" unless err.empty?
  File.write(file, out)
end

yes = ARGV.delete('--yes')
repo = case ARGV[0]
when 'hs'; 'haskell'.freeze
when 'rs'; 'rust'.freeze
else raise "bad repo #{ARGV[0]}"
end

track = "#{__dir__}/../#{repo}".freeze
practices = Dir.glob("#{track}/exercises/practice/*/")
track_config = JSON.parse(File.read("#{track}/config.json"))
track_config_changed = false
toml = %r{^(\w+) = "(.+)"$}

practices.each { |practice|
  exercise = File.basename(practice)
  f = "#{__dir__}/exercises/#{exercise}/metadata.toml"
  next unless File.exist?(f)
  meta = File.readlines(f).to_h { |l|
    raise "bad #{l}" unless m = toml.match(l)
    [m[1], m[2].gsub('\"', '"').freeze]
  }
  track_config_exercise = track_config['exercises']['practice'].find(-> { raise "no #{exercise} in config" }) { |ex| ex['slug'] == exercise }

  track_config_changed |= set(exercise, track_config_exercise, 'name', meta['name'], yes: yes)

  exercise_config = JSON.parse(File.read("#{practice}/.meta/config.json"))
  config_changed = false
  config_changed |= set(exercise, exercise_config, 'blurb', meta.fetch('blurb'), yes: yes)
  config_changed |= set(exercise, exercise_config, 'source', meta['source'], nil_deletes: true, yes: yes)
  config_changed |= set(exercise, exercise_config, 'source_url', meta['source_url'], nil_deletes: true, yes: yes)
  write_json("#{practice}/.meta/config.json", exercise_config) if yes && config_changed
}

write_json("#{track}/config.json", track_config) if yes && track_config_changed
