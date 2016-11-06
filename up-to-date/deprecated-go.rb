require_relative 'up-to-date'

# Deprecated.
# I don't maintain Go anymore.
# Therefore, I have no way of knowing whether this method of detection still works.

IGNORE_EXERCISES = {
  'hello-world' => 'no version',
  'diamond' => 'property-based',
}

GO = "#{__dir__}/../../go".freeze

UpToDate.report(GO, IGNORE_EXERCISES) { |dir|
  test_files = Dir.glob(File.join(dir, '*_test.go'))
  version_lines = test_files.flat_map { |f|
    File.readlines(f).grep(/Problem Specifications Version:/)
  }

  # Temporary? Non-generated exercises don't have them yet, but maybe they can be manually added.
  next '0.0.0' if version_lines.empty?

  raise "Need one version line among #{test_files}, got #{version_lines}" if version_lines.size != 1
  version_lines.first.split(': ').last.strip
}
