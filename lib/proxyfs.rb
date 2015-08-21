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

      if Array === @entry
        @file = @entry[0].new(*@entry[1..(-1)])
      elsif Hash === e
      else
        @file = @entry
      end
    end

    define_proxy_method = Proc.new do |method, method_name|
      self.send method, method_name do |*args, &block|
        e = @entry.nil? ? fs.entry(args.shift) : @entry

        if Array === e
          f = @file.nil? ? e[0].new(*e[1..(-1)]) : @file
          f.send method_name, *args, &block
        elsif Hash === e
          raise ArgumentError, 'it is directory'
        else
          f = @entry.nil? ? e : @entry
          f.send method_name, *args, &block
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

    [:read, :write, :seek, :binmode].each do |name|
      define_proxy_method[:define_method, name]
    end

    [:read, :write].each do |name|
      define_proxy_method[:define_singleton_method, name]
    end
  end

  class Dir
    def initialize path
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

      raise ArgumentError, 'path shall be absolute' unless path.absolute?

      patha = path.each_filename.to_a

      find = Proc.new do |patha, curdir|
        name = patha[0]
        raise Errno::ENOENT unless curdir.include? name

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
  end
end

