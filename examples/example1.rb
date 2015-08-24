require 'proxyfs'
require 'stringio'

include ProxyFS

$root = VirtualDirEntry.new({
  'file1' => LocalFileEntry.new('/etc/fstab'),
  'file2' => VirtualFileEntry.new('Hello, world!'),
  'dir1' => LocalDirEntry.new('/etc'),
  'dir2' => VirtualDirEntry.new({
    'file1' => VirtualFileEntry.new('Blablabla'),
  }),
})

$root.make_root

$d = $root.entry '/dir1'

