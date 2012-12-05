require 'link_checker/celluloid'

source_file = ARGV[0]
prechecker_pool_size = ARGV[1] ? ARGV[1].to_i : 5
checksum_pool_size = ARGV[2] ? ARGV[2].to_i : 5

urls = File.readlines(source_file).map do |url|
  LinkChecker::Link.new(url)
end

results = []
LinkChecker.logger = Celluloid.logger

LinkChecker::Process.new do |process|
  prechecker  = LinkChecker::Prechecker.new_link.async
  checksummer = LinkChecker::Checksummer.new_link(Digest::MD5.method(:hexdigest)).async
  fetcher     = LinkChecker::ChecksumFetcher.new_link(checksummer: checksummer).async
                 
  process.source  = urls
  process.updater = LinkChecker::Updater.new_link(
    prechecker: prechecker,
    checksum_fetcher: fetcher
  )
  process.store   = results
end.execute

puts results.join("\n")
