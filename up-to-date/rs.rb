require_relative 'up-to-date'

IGNORE_EXERCISES = {
}

RUST = "#{__dir__}/../../rust".freeze

UpToDate.report(RUST, IGNORE_EXERCISES) { |dir|
  version_lines = File.readlines(File.join(dir, 'Cargo.toml')).grep(/version/)
  raise "Need one version line, got #{version_lines}" if version_lines.size != 1

  version_lines.first.split(?")[1]
}
