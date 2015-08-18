module ProxyFS
  class Dir
    def glob pattern
      []
    end
  end

  class File
    @name
    @data
    
    def initizalize name, options={}
      @name = name

      if options.has_key? :data
        @data = options[:data]
      elsif options.has_key? :local
        @data = File.new options[:local].to_s
      end
    end

    def directory?
      false
    end

    def size
      0
    end

    def ctime
      Time.now
    end

    def atime
      Time.now
    end

    def mtime
      Time.now
    end

    def readable?
      false
    end

    def writable?
      false
    end

    def binread name, length=nil, offset=nil
      nil
    end

    def binwrite name, string, offset=nil
      0
    end
  end
end

