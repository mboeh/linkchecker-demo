require 'link_checker/spike'
require 'logger'

source_file = ARGV[0]

urls = File.readlines(source_file).map do |url|
  LinkChecker::Link.new(url)
end

results = []
LinkChecker.logger = Logger.new(STDERR)

LinkChecker::Process.new do |process|
  prechecker = LinkChecker::Prechecker.new
  checksummer = LinkChecker::Checksummer.new( Digest::MD5.method(:hexdigest) )
  fetcher = LinkChecker::ChecksumFetcher.new(checksummer: checksummer)

  process.source  = urls
  process.updater = LinkChecker::Updater.new(
    prechecker: prechecker,
    checksum_fetcher: fetcher
  )
  process.store   = results
end.execute

puts results.join("\n")
