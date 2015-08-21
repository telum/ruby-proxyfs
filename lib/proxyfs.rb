require 'pathname'


class Dir
  def [] name
    raise Errno::ENOENT unless include? name

    fpath = File.join(path, name)

    File.directory?(fpath) ? Dir.new(fpath) : File.open(fpath)
  end
end


module ProxyFS
  class File
    @path
    @entry
    @file

    def initialize path
      @path = path
      @entry = fs.entry(@path)

      puts @entry

      raise Errno::ENOENT if @entry.nil?

      if Array === @entry
        @file = @entry[0].new(*@entry[1..(-1)])
      elsif Hash === @entry
      else
        @file = @entry
      end
    end

    define_proxy_method = Proc.new do |method_name|
      define_method method_name do |*args, &block|
        if Array === @entry
            f = @file.nil? ? @entry[0].new(*@entry[1..(-1)]) : @file
            f.send method_name, *args, &block
        elsif Hash === @entry
          raise ArgumentError, 'it is directory'
        else
          @entry.send method_name, *args, &block
        end
      end
    end

    define_singleton_proxy_method = Proc.new do |method_name|
      define_singleton_method method_name do |*args, &block|
        e = fs.entry(args.shift)

        raise Errno::ENOENT if e.nil?

        if Array === e
            f = e[0].new(*e[1..(-1)])
            f.send method_name, *args, &block
        elsif Hash === e
          raise ArgumentError, 'it is directory'
        else
          e.class.send method_name, *args, &block
        end
      end
    end

    def self.binread name, length=nil, offset=nil
      f = self.new name
      f.binmode
      f.seek offset if offset
      f.read *([length].compact)
    end

    def self.binwrite name, string, offset=nil
      f = self.new name
      f.binmode
      f.seek offset if offset
      f.write string
    end

    def self.readable? path
      !fs.entry(path).nil?
    end

    [:read, :write, :seek, :binmode, :exist?, :directory?, :size, :atime, :ctime, :mtime].each do |name|
      define_proxy_method[name]
    end

    [:read, :write, :exist?, :directory?, :size, :atime, :ctime, :mtime].each do |name|
      define_singleton_proxy_method[name]
    end
  end

  class Dir
    def initialize path
    end

    def self.glob pattern
      puts Pathname.new(pattern).dirname.to_s
      entries Pathname.new(pattern).dirname.to_s
    end

    def self.entries path
      fs.entries(path).keys
    end
  end

  class FS
    @tree
    attr_reader :dir,:file

    def initialize tree
      @tree = tree
      iam = self

      @dir = Class.new Dir do
        @@fs = iam

        def self.fs
          @@fs
        end

        def fs
          @@fs
        end
      end

      @file = Class.new File do
        @@fs = iam

        def self.fs
          @@fs
        end

        def fs
          @@fs
        end
      end
    end

    def entry path
      path = Pathname.new path

      unless path.absolute?
        path = Pathname.new('/' + path.to_s)
      end

      return nil unless path.absolute?

      return @tree if path == Pathname.new('/')

      patha = path.each_filename.to_a

      find = Proc.new do |patha, curdir|
        name = patha[0]
        raise Errno::ENOENT, name unless curdir.include? name

        e = curdir[name]

        rest_patha = patha[1..(-1)]

        if rest_patha.empty?
          e
        else
          if Hash === e
            find[rest_patha, e]
          elsif Array === e
            find[rest_patha, e[0].new(*e[1..(-1)])]
          else
            find[rest_patha, e]
          end
        end
      end

      find[patha, @tree]
    end

    def entries path
      dirent = entry(path)

      if Hash === dirent
        dirent
      elsif Array === dirent
        dir = dirent[0].new(*dirent[1..(-1)])
        raise ArgumentError, 'destination is not a directory' unless dir.respond_to?(:directory?) and dir.directory?
        dir.entries.inject({}) do |hash,name|
          hash[name] = dir[name]
        end
      else
        dirent.entries.inject({}) do |hash,name|
          hash[name] = dirent[name]
        end
      end
    end
  end

  class FileEntry
    @klass
    @args

    def initialize klass, *args
      @klass = klass
      @args = args
    end
  end

  class DirEntry
    @klass
    @args

    def initialize klass, *args
      @klass = klass
      @args = args
    end
  end
end

