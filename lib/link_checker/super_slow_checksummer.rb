module LinkChecker
  
  class SuperSlowChecksummer

    def initialize(slowness = 750)
      @slowness = slowness
    end

    def call(content)
      @slowness.times do
        Digest::MD5.hexdigest(content)
      end
      Digest::MD5.hexdigest(content)
    end
  
  end

end
