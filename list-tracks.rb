require 'json'

tracks = JSON.parse(`curl -H 'Accept: application/vnd.github.mercy-preview+json' 'https://api.github.com/search/repositories?q=topic:exercism-track+org:exercism&per_page=100'`)

puts 'WARNING!!! INCOMPLETE RESULTS!!!' if tracks['incomplete_results']

puts tracks['items'].map { |t| t['name'] }.sort
