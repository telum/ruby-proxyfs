require 'pathname'


#TODO:
def path_next_entry base_path, path
  base_path += '/' unless base_path[-1] == '/'
  return nil unless path.index(base_path) == 0

  path[(base_path.length)..(-1)].split(File::SEPARATOR)[0]
end

#TODO:
def path_next_entry_last? base_path, path
  base_path += '/' unless base_path[-1] == '/'
  return nil unless path.index(base_path) == 0

  path[(base_path.length)..(-1)].split(File::SEPARATOR).count < 2
end


module ProxyFS
  module FsEntry
    attr_accessor :root, :basename, :path

    def entry entry_path
      cur_path = File.join(path, basename)
      next_entry = path_next_entry cur_path, entry_path
      puts "(#{cur_path}, #{entry_path}) => #{next_entry}"

      if path_next_entry_last? cur_path, entry_path
        self[next_entry]
      else
        return nil unless DirEntry === self[next_entry]

        self[next_entry].entry entry_path
      end
    end

    def [] name
      nil
    end

    def each &block
    end
  end

  class FileEntry
    include FsEntry
  end

  class DirEntry
    include FsEntry
  end

  class VirtualDirEntry < DirEntry
    @dir

    def initialize dirDesc, options={}
      @dir = dirDesc
    end

    def make_root
      self.path = '/'
      self.basename = '/'

      dir_init = Proc.new do |dir|
        dir.each do |(name, entry)|
          entry.root = self
          entry.basename = name
          entry.path = File.join(dir.path, dir.basename)

          dir_init[entry] if DirEntry === entry
        end
      end

      dir_init[self]
    end

    def [] name
      @dir[name]
    end

    def each &block
      @dir.each do |(name,e)| yield [name, e] end
    end

    def class_file
      iam = self
      klass = Class.new do
        @@root = iam

        define_proxy_singleton_method = Proc.new do |method|
          define_singleton_method method do |path, *args, &block|
            e = @@root.entry path
            e.class.send method, e, *args, &block
          end
        end

        [:read, :write, :size, :binread, :binwrite].each do |method|
          define_proxy_singleton_method[method]
        end
      end
    end
  end

  class VirtualFileEntry < FileEntry
    @data

    def initialize data
      @data = StringIO.new data.to_s
    end

    define_proxy_method = Proc.new do |method|
      define_method method do |*args, &block|
        @data.send method, *args, &block
      end
    end

    [:read, :write, :size, :seek].each do |method|
      define_proxy_method[method]
    end

    def ctime
      Time.now
    end

    alias_method :atime, :ctime
    alias_method :mtime, :ctime
  end

  class LocalFileEntry < FileEntry
    @file

    def initialize path
      @file = File.new path
    end

    define_proxy_method = Proc.new do |method|
      define_method method do |*args, &block|
        @file.send method, *args, &block
      end
    end

    define_proxy_singleton_method = Proc.new do |method|
      define_singleton_method method do |entry, *args, &block|
        def entry.real_path
          @file.path
        end

        File.send method, entry.real_path, *args, &block
      end
    end

    [:read, :write, :size, :seek].each do |method|
      define_proxy_method[method]
    end

    [:read, :write, :size, :binread, :binwrite].each do |method|
      define_proxy_singleton_method[method]
    end
  end

  class LocalDirEntry < DirEntry
    @dir

    def initialize path
      @dir = Dir.new path
    end

    def [] name
      return nil unless @dir.include? name

      d = LocalDirEntry.new File.join(@dir.path, name)
      d.basename = name
      d.path = File.join(self.path, self.basename)
      d.root = @root
      d
    end

    def each &block
      #@dir.each do |(name,e)| yield [name, e] end
    end
  end
end

