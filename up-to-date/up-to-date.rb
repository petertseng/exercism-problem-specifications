require 'date'
require 'json'
require 'set'
require 'shellwords'

module Version refine String do
  def version_components
    split(?.).map(&:to_i)
  end
end end

module UpToDate
  RED = 31
  GREEN = 32
  YELLOW = 33

  using Version

  # Returns a colour and string classifying an exercise as up to date, out of date, etc.
  def self.classify(name, track_ver, deprecated)
    return [GREEN, 'DEPRECATED'] if deprecated.include?(name)
    json_file = "#{__dir__}/../exercises/#{name}/canonical-data.json"
    return [GREEN, "#{track_ver} - still no JSON file"] unless File.exist?(json_file)

    begin
      x_common_ver = JSON.parse(File.read(json_file)).fetch('version')
    rescue
      puts "Can't parse #{name}"
      raise
    end

    # For those tracks that define an additional component (e.g. Haskell with 1.0.0.1), compare only as many components as exist.
    components = x_common_ver.version_components
    cmp = track_ver.version_components.take(components.size) <=> components

    if cmp < 0
      [RED, "#{track_ver} < #{x_common_ver}"]
    elsif cmp > 0
      # This is weird, right? Why would the track have a newer version? Flag this as red.
      [RED, "#{track_ver} > #{x_common_ver}"]
    else
      [GREEN, "#{track_ver} = #{x_common_ver}"]
    end
  end

  # track_dir: path to track repo, should contain config.json and exercises dir.
  # ignore_exercises: Hash[String => String]
  #   key: exercise to ignore and always treat as up-to-date
  #   value: reason why that exercise is ignored.
  #   should only be used if the track diverges intentionally.
  #
  # block: Each exercise directory will be yielded to the block.
  # The block is expected to produce a String: the version of that exercise.
  def self.report(track_dir, ignore_exercises = {})
    deprecated = Set.new(JSON.parse(File.read(File.join(track_dir, 'config.json')))['exercises'].select { |e| e['deprecated'] }.map { |e| e['slug'] })

    Dir.glob(File.join(track_dir, 'exercises', '*/')) { |dir|
      name = File.basename(dir)
      raise "Weird name #{name}" unless name =~ /^[-a-z]+$/

      dat = if (reason = ignore_exercises[name])
        [YELLOW, "IGNORED: #{reason}"]
      else
        ver = yield dir
        classify(name, ver, deprecated)
      end

      puts "%30s: \e[1;%dm%s\e[0m" % [name, *dat]
    }
  end
end
