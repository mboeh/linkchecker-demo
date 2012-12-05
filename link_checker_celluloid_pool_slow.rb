require 'bundler/setup'
require 'link_checker/celluloid'
require 'link_checker/super_slow_checksummer'

source_file = ARGV[0]
prechecker_pool_size = ARGV[1] ? ARGV[1].to_i : 5
checksum_pool_size = ARGV[2] ? ARGV[2].to_i : 5

urls = File.readlines(source_file).map do |url|
  LinkChecker::Link.new(url)
end

results = []
LinkChecker.logger = Celluloid.logger

process = LinkChecker::Process.new do |process|
  prechecker  = LinkChecker::Prechecker.pool(size: prechecker_pool_size).async
  checksummer = LinkChecker::Checksummer.pool(size: checksum_pool_size, args: [LinkChecker::SuperSlowChecksummer.new]).async
  fetcher     = LinkChecker::ChecksumFetcher.pool(size: checksum_pool_size, args: [{checksummer: checksummer}]).async
  supervisor  = LinkChecker::JobSupervisor.new_link(urls, results)

  process.source  = supervisor
  process.updater = LinkChecker::Updater.new_link(
    prechecker: prechecker,
    checksum_fetcher: fetcher
  )
  process.store   = supervisor
end

process.execute
process.store.wait :done

puts results.join("\n")
