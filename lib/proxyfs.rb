module ProxyFS
  class VirtualDir
    def initialize dir_data
    end
  end

  def self.dir root
    res = Class.new

    res.class_eval do
      def initialize
        @root = root
      end

      def glob pattern, flags=nil, &block
        raise ArgumentError, 'Relative path is not supported' if pattern[0] != '/'

        cFile = file @root
        res = []
        parts = pattern.split '/'

        lglob = Proc.new do |dir, parts|
          parts.each_with_index do |part, i|
            file_names = dir.select do |file| file.basename == part end
            files = file_names.map do |name| cFile.new path+name end
            
            files.each do |file|
              parts_rest = parts[i..(-1)]
              lglob file, parts_rest if file.directory?
              res << file if parts_rest.empty?
            end
          end
        end

        lglob[@root, parts]

        res
      end
    end

    res
  end

  def self.file root
    res = Class.new

    res.class_eval do
      @@root = root
      @file
      @path

      def initialize path, mode="r"
        f = self.class.entry_by_path path

        raise ArgumentError, 'Path is a directory' if f.directory?

        @file = f
        @path = path
      end

      def self.entry_by_path path
        parts = path.split '/'

        raise ArgumentError, 'Relative path is not supported' unless parts[0].empty?
        parts.delete_at 0

        dir = @@root

        basename = parts.pop

        parts.each do |part|
          tmp = dir[part]

          return nil unless tmp && tmp.directory?

          dir = tmp
        end

        dir[basename]
      end

      def self.define_proxy_method method_name
        define_method method_name do |*args, &block|
          @file.send method_name, *args, &block
        end
      end

      def self.define_singleton_proxy_method method_name
        define_singleton_method method_name do |*args, &block|
          file = self.new(args[0])
          file_class = file.file_class

          if file.file_class.respond_to? method_name
            file_class.send method_name, file.real_file_path, *args[1..(-1)], &block
          else
            file.send method_name, *args[1..(-1)]
          end
        end
      end

      [
        :read, :write, :size, :atime, :mtime, :ctime,
        :flock, :truncate, :chmod, :chown, :binmode,
        :seek
      ].each do |method|
        define_proxy_method method
      end

      [
        :read, :write, :size, :atime, :mtime, :ctime,
        :binread, :binwrite
      ].each do |method|
        define_singleton_proxy_method method
      end

      def self.binread *args
          file = self.new(args.shift)
          file.binmode

          if args.count == 2
            file.seek args.pop
          end

          file.read *args
      end

      def self.binwrite *args
          file = self.new(args.shift)
          file.binmode

          if args.count == 2
            file.seek args.pop
          end

          file.write *args
      end

      def path
        @path
      end

      def to_path
        path
      end

      def file_class
        @file.class
      end

      def real_file_path
        @file.path
      end
    end

    res
  end
end

