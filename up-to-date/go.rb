require_relative 'up-to-date'

IGNORE_EXERCISES = {
}

IGNORE_COMMITS = {
  all: [
    # These move commits don't change test content.
    'cda8f98 Create new exercises structure',
  ],
}

GO = "#{__dir__}/../../xgo".freeze

UpToDate.report(GO, IGNORE_EXERCISES, IGNORE_COMMITS) { |dir|
  name = File.basename(dir)
  test_file = File.join(dir, '*_test.go')
  Dir.chdir(GO) {
    # Can't --follow with multiple files, since we are using *.
    # Additionally, you would think the shellescape would remove the *,
    # but git seems to understands globbing.
    # Conjecture for why: shell globs won't find deleted files,
    # but git globs will!
    commits = UpToDate.git_log(test_file, follow: false)
    if commits.first['yyyy-mm-dd '.size..-1] == 'd895e12 Move exercises to subdirectory. Fixes #223'
      # d895e12 is going to be the most recent commit on the old path too, so drop it.
      commits = UpToDate.git_log(File.join(GO, name, '*_test.go'), n: 2, follow: false).drop(1)
    end
    Date.parse(commits.first.split.first)
  }
}
