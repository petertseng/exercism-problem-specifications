require_relative 'up-to-date'

IGNORE_EXERCISES = {
}

RUBY = "#{__dir__}/../../ruby".freeze

UpToDate.report(RUBY, IGNORE_EXERCISES) { |dir|
  test_files = Dir.glob(File.join(dir, '*_test.rb'))
  version_lines = test_files.flat_map { |f|
    File.readlines(f).grep(/Common test data version:/)
  }
  next '0.0.0' if version_lines.empty?
  raise "Need one version line among #{test_files}, got #{version_lines}" if version_lines.size != 1

  version_lines.first.split[-2]
}
