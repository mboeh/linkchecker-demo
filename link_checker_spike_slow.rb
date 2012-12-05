require 'bundler/setup'
require 'link_checker/spike'
require 'link_checker/super_slow_checksummer'
require 'logger'

source_file = ARGV[0]

urls = File.readlines(source_file).map do |url|
  LinkChecker::Link.new(url)
end

results = []
LinkChecker.logger = Logger.new(STDERR)

LinkChecker::Process.new do |process|
  prechecker = LinkChecker::Prechecker.new
  checksummer = LinkChecker::Checksummer.new( LinkChecker::SuperSlowChecksummer.new )
  fetcher = LinkChecker::ChecksumFetcher.new(checksummer: checksummer)

  process.source  = urls
  process.updater = LinkChecker::Updater.new(
    prechecker: prechecker,
    checksum_fetcher: fetcher
  )
  process.store   = results
end.execute

puts results.join("\n")
