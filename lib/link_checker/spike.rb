require 'delegate'
require 'digest/md5'
require 'net/http'
require 'date'

module LinkChecker
 
  class << self
    attr_accessor :logger
  end

  module Conversions
    
    def Time(value)
      return if value.nil?
      return value.to_time if value.respond_to?(:to_time)
      return DateTime.parse(value).to_time
    end

  end

  module Common
    attr_accessor :logger

    def logger
      @logger ||= LinkChecker.logger
    end

    def log(msg)
      logger.info("[#{self.class.name}:#{object_id}] #{msg}") if logger
    end

  end

  class Link
    include Conversions

    attr_accessor :url, :last_modified, :checksum
    
    def initialize(url, last_modified = nil, checksum = nil)
      self.url           = url
      self.last_modified = last_modified
      self.checksum      = checksum

      freeze
    end

    def url=(value)
      @url = value ? URI(value) : nil
    end

    def last_modified=(value)
      @last_modified = Time(value) 
    end

    def to_s
      "#{url} checked: #{last_modified}, checksum: #{checksum}"
    end

    def rfc2822
      last_modified and last_modified.rfc2822
    end

    def with_last_modified(time)
      self.class.new(url, time, nil)
    end

    def with_checksum(sum)
      self.class.new(url, last_modified, sum)
    end

  end

  class Process
    attr_accessor :source, :updater, :store
    
    include Common

    def initialize(keyw = {}, &blk)
      self.source  = keyw[:source]
      self.updater = keyw[:updater]
      self.store   = keyw[:store]
      
      instance_eval &blk if block_given? 
    end

    def execute
      source.each do |link|
        updater.update link, to: store
      end
    end

  end

  class Updater
    attr_accessor :prechecker, :checksum_fetcher

    include Common

    def initialize(keyw = {})
      self.prechecker       = keyw.fetch :prechecker
      self.checksum_fetcher = keyw.fetch :checksum_fetcher

      @jobs = []
    end

    def update(link, keyw = {})
      prechecker.check(link, fresh_to: checksum_fetcher, to: keyw[:to])
    end

  end

  module HTTPInteraction

    def http_session(url, &blk)
      Net::HTTP.start(url.hostname, url.port, &blk)
    end

    def head_request(url)
      Net::HTTP::Head.new(url.request_uri)
    end

    def get_request(url)
      Net::HTTP::Get.new(url.request_uri)
    end

    def fresh_response?(response)
      response.kind_of?(Net::HTTPSuccess)
    end

  end

  class Prechecker
    include HTTPInteraction
    include Common

    def check(link, keyw = {})
      log "checking #{link}"
      if new_link = check_link(link)
        keyw[:fresh_to].fetch(new_link, to: keyw[:to])
      else
        keyw[:to] << link
      end
    end

    def check_link(link)
      response = http_session(link.url) do |session|
        probe = head_request(link.url)
        probe['If-Modified-Sense'] = link.rfc2822
        session.request probe
      end

      if fresh_response? response
        link.with_last_modified response['Last-Modified']
      end
    end
    
  end

  class ChecksumFetcher
    include HTTPInteraction
    include Common

    attr_accessor :checksummer

    def initialize(keyw = {})
      self.checksummer = keyw[:checksummer]
    end

    def fetch(link, keyw = {})
      response = http_session(link.url) do |session|
        log "requesting #{link.url}"
        session.request get_request(link.url)
      end

      checksummer.checksum(link, response.body, to: keyw[:to])
    end

  end

  class Checksummer 
    include Common

    attr_accessor :checksum_method

    def initialize(checksum_method, keyw = {})
      self.checksum_method = checksum_method
    end

    def checksum(link, content, keyw = {})
      log "checksumming #{link}"

      keyw[:to] << link.with_checksum(checksum_method.(content))
    end

  end

end
