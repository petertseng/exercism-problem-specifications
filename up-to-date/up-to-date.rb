require 'date'
require 'json'
require 'set'
require 'shellwords'

module UpToDate
  RED = 31
  GREEN = 32
  YELLOW = 33
  GIT_FORMAT = '--date=short --pretty=format:"%ad %h %s"'.freeze

  def self.git_log(file, n: 1, follow: true)
    `git log #{'--follow' if follow} #{GIT_FORMAT} -n#{n} #{file.shellescape}`.lines.map(&:strip)
  end

  # Returns a colour and string classifying an exercise as up to date, out of date, etc.
  def self.classify(name, date, deprecated, ignore_commits, ignore_counts)
    return [GREEN, 'DEPRECATED'] if deprecated.include?(name)
    return [RED, date] if !date.is_a?(Date)
    json_file = "#{__dir__}/../exercises/#{name}/canonical-data.json"
    return [GREEN, "#{date} - still no JSON file"] unless File.exist?(json_file)

    commits_since = `git log --oneline --follow --after #{date} #{json_file.shellescape}`.lines.map(&:strip)
    commits_since = commits_since.drop_while { |c|
      ignore_commits.include?(c.strip) && ignore_counts[c.strip] += 1
    }

    return [RED, "#{date} - commits since: #{commits_since}"] unless commits_since.empty?

    # At this point, the file is safe.
    # There are no x-common commits since the track's last edit date.
    # We don't have to do this, but for informational purposes,
    # let's show the last commit to the file.
    commits = git_log(json_file, n: ignore_commits.size + 1)
    first_unignored = commits.find { |c|
      c_without_date = c['yyyy-mm-dd '.size..-1]
      # For this one, we don't bump the ignore count,
      # since this one didn't affect the up-of-date decision.
      !ignore_commits.include?(c_without_date)
    }
    return [GREEN, "#{date} - all ignored"] unless first_unignored

    first_date = Date.parse(first_unignored.split.first)
    diff = date - first_date
    # If the most recent was pretty close, highlight it for examination.
    # Timezones could cause a difference, etc.
    [diff <= 1 ? YELLOW : GREEN, "#{date} - last #{first_unignored}"]
  end

  # track_dir: path to track repo, should contain config.json and exercises dir.
  # ignore_exercises: Hash[String => String]
  #   key: exercise to ignore and always treat as up-to-date
  #   value: reason why that exercise is ignored.
  #   should only be used if the track diverges intentionally.
  # ignore_commits: Hash[String|Symbol => Array[String]]
  #   key: :all to apply to all exercises, string to only apply to that exercise
  #   value: commits to ignore for that exercise
  #   should be used when it's confirmed these commits don't affect test content.
  #
  # block: Each exercise directory will be yielded to the block.
  # The block is expected to produce a Date object,
  # representing the date of the most recent commit affecting that exercise's tests.
  # If any other object is produced, the report records an error (red) for that exercise.
  def self.report(track_dir, ignore_exercises = {}, ignore_commits = {})
    ignore_counts = ignore_commits.values.flatten.map { |s| [s, 0] }.to_h

    deprecated = Set.new(JSON.parse(File.read(File.join(track_dir, 'config.json')))['deprecated'])

    Dir.glob(File.join(track_dir, 'exercises', '*/')) { |dir|
      name = File.basename(dir)
      raise "Weird name #{name}" unless name =~ /^[-a-z]+$/

      dat = if (reason = ignore_exercises[name])
        [YELLOW, "IGNORED: #{reason}"]
      else
        date = yield dir
        classify(
          name, date, deprecated,
          ignore_commits.fetch(:all, []) + ignore_commits.fetch(name, []),
          # ignore_counts is MUTATED by classify
          ignore_counts,
        )
      end

      puts "%30s: \e[1;%dm%s\e[0m" % [name, *dat]
    }

    # Show how many times each commit was ignored.
    # If it was ignored zero times, the commit doesn't need to be ignored anymore!
    puts 'x-common ignored commits:'
    ignore_counts.each { |c, n| puts '%2d: %s' % [n, c] }
  end
end
