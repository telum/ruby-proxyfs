require 'proxyfs'
require 'stringio'


root = {
  'file1' => [ File, '/etc/fstab' ],
  'file2' => [ StringIO, 'Hello, world!' ],
  'dir1' => [ Dir, '/etc' ],
  'dir2' => {
    'file1' => [ StringIO, 'Blablabla' ],
  },
}

Fs = ProxyFS::FS.new root

MyDir  = Fs.dir
MyFile = Fs.file

puts MyFile.new('/dir2/file1').read

