module ProxyFS
  def dir root
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
  end

  def file root
    res = Class.new
  end
end

