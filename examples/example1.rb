require 'proxyfs'
require 'stringio'
require_relative 'debug'

class Dir
  def [] (name)
    return nil unless entries.include? name

    res_path = File.join(path, name)
    File.directory?(res_path) ? Dir.new(res_path) : File.new(res_path)
  end

  def directory?
    true
  end
end

class File
  def directory?
    false
  end
end

class StringIO
  def directory?
    false
  end
end

class ProxyDir
  @data

  def initialize dir_data
    raise ArgumentError, 'dir_data shall be Hash' unless Hash === dir_data

    @data = dir_data
  end

  def [] (name)
    res = @data[name]

    res ? res[0].new(*res[1..(-1)]) : nil
  end

  def directory?
    true
  end
end

$root = ProxyDir.new({
  'file1' => [ File, '/etc/fstab' ],
  'file2' => [ StringIO, 'Hello, world!' ],
  'dir1' => [ Dir, '/etc' ],
  'dir2' => [ ProxyDir, {
    'file1' => [ StringIO, 'Blablabla' ],
  } ],
})

#MyDir = ProxyFS.dir root
MyFile = ProxyFS.file $root

#BP[binding]

