require_relative 'up-to-date'

TRACK_IGNORE_COMMITS = [
].map { |s| [s, 0] }.to_h

IGNORE_EXERCISES = {
}

IGNORE_COMMITS = {
  all: [
    # These move commits don't change test content.
    'cda8f98 Create new exercises structure',
  ],
}

CEYLON = "#{__dir__}/../../xceylon".freeze

UpToDate.report(CEYLON, IGNORE_EXERCISES, IGNORE_COMMITS) { |dir|
  commits = Dir.chdir(CEYLON) {
    # No follow needed: ceylon has used exercises since day 1.
    # This means we can let git do the globbing.
    UpToDate.git_log(
      File.join(dir, 'source', '*', '*Test.ceylon'),
      n: TRACK_IGNORE_COMMITS.size + 1,
      follow: false,
    )
  }.drop_while { |c|
    c_without_date = c['yyyy-mm-dd '.size..-1]
    TRACK_IGNORE_COMMITS.include?(c_without_date) && TRACK_IGNORE_COMMITS[c_without_date] += 1
  }
  Date.parse(commits.first.split.first)
}

puts 'Ceylon ignored commits:'
TRACK_IGNORE_COMMITS.each { |c, n| puts '%2d: %s' % [n, c] }
