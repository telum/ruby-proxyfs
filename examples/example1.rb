require 'pathname'
require 'proxyfs'
require_relative 'debug'


class VirtualDir
  def initialize dir_data
  end
end

class VirtualFile
  def initialize file_data
  end
end

root = [ VirtualDir, {
  'file1' => [ File, '/etc/fstab' ],
  'file2' => [ VirtualFile, 'Hello, world!' ],
  'dir1' => [ Dir, '/etc' ],
  'dir2' => [ VirtualDir, {
    'file1' => [ VirtualFile, 'Blablabla' ],
  } ],
} ]

MyDir = ProxyFS::dir root
MyFile = ProxyFS::file root

BP[binding]

