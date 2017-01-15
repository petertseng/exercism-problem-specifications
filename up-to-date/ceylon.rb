require_relative 'up-to-date'

IGNORE_EXERCISES = {
}

CEYLON = "#{__dir__}/../../ceylon".freeze

UpToDate.report(CEYLON, IGNORE_EXERCISES) { |dir|
  test_files = Dir.glob(File.join(dir, 'source', ?*, '*Test.ceylon'))
  version_lines = test_files.flat_map { |f|
    File.readlines(f).grep(/problem-specifications version/)
  }
  raise "Need one version line among #{test_files}, got #{version_lines}" if version_lines.size != 1
  version_lines.first.split.last
}
