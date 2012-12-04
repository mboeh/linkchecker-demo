require 'link_checker/spike'

urls = File.readlines('url-list').map do |url|
  LinkChecker::Link.new(url)
end

LinkChecker::Process.new do |process|
  process.source  = urls
  process.updater = LinkChecker::Updater.new(
    prechecker:       LinkChecker::Prechecker.new,
    checksum_fetcher: LinkChecker::ChecksumFetcher.new(
      checksummer:      Digest::MD5.method(:hexdigest) 
    )
  )
  process.store   = Class.new(SimpleDelegator) do
    def <<(o) super "#{o}\n" end
  end.new(STDOUT)
end.execute
