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

    def initialize path
      @path = path
    end

    def read *args
      e = fs.entry(@path)

      if Array === e
        f = e[0].new(*e[1..(-1)])
        f.read *args
      elsif Hash === e
        raise ArgumentError, 'it is directory'
      else
        e.read *args
      end
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

