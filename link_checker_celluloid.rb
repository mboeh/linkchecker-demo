require 'link_checker/celluloid'

urls = File.readlines('url-list').map do |url|
  LinkChecker::Link.new(url)
end

LinkChecker::Process.new do |process|
  process.source  = urls
  process.updater = LinkChecker::Updater.new_link(
    prechecker:       LinkChecker::Prechecker.pool(size: 2),
    checksum_fetcher: LinkChecker::ChecksumFetcher.pool(args: [{
      checksummer:      Digest::MD5.method(:hexdigest) 
    }], size: 2)
  )
  process.store   = Class.new(SimpleDelegator) do
    def <<(o) super "#{o}\n" end
  end.new(STDOUT)
end.execute
