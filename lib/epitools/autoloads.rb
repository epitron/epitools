## Standard library

autoload :Set,        'set'
autoload :URI,        'uri'
autoload :Zlib,       'zlib'
autoload :FileUtils,  'fileutils'
autoload :Tempfile,   'tempfile'
autoload :BigDecimal, 'bigdecimal'
autoload :StringIO,   'stringio'
autoload :Curses,     'curses'
autoload :DateTime,   'date'
autoload :Date,       'date'
autoload :Open3,      'open3'
autoload :OpenStruct, 'ostruct'
autoload :Timeout,    'timeout'
autoload :Find,       'find'
autoload :Benchmark,  'benchmark'
autoload :Tracer,     'tracer'
autoload :TSort,      'tsort'
autoload :Shellwords, 'shellwords'
autoload :PTY,        'pty'
autoload :CSV,        'csv'
autoload :SDBM,       'sdbm'
autoload :StringScanner, 'strscan'

module Digest
  autoload :SHA1,     'digest/sha1'
  autoload :SHA2,     'digest/sha2'
  autoload :SHA256,   'digest/sha2'
  autoload :SHA384,   'digest/sha2'
  autoload :SHA512,   'digest/sha2'
  autoload :MD5,      'digest/md5'
end

if RUBY_VERSION["1.8.7"]
  autoload :Prime,      'mathn'
else
  autoload :Prime,      'prime'
end


## Networking

['IP', 'Basic', 'TCP', 'UDP', 'UNIX', ''].each do |type|
  autoload :"#{type}Socket", 'socket'
end

['TCP', 'UNIX'].each do |type|
  autoload :"#{type}Server", 'socket'
end

module Net
  autoload :HTTP,  'net/http'
  autoload :HTTPS, 'net/https'
  autoload :FTP,   'net/ftp'
  autoload :FTP,  'net/ftp'
end

autoload :Resolv, 'resolv'
autoload :IPAddr, 'ipaddr'


## Nonstandard library (epitools)

autoload :Path,         'epitools/path'
autoload :Ezdb,         'epitools/ezdb'
autoload :Browser,      'epitools/browser'
autoload :Rash,         'epitools/rash'
autoload :Ratio,        'epitools/ratio'
autoload :ProgressBar,  'epitools/progressbar'
autoload :Trie,         'epitools/trie'
autoload :MimeMagic,    'epitools/mimemagic'
autoload :Term,         'epitools/term'
autoload :Iter,         'epitools/iter'
autoload :WM,           'epitools/wm'
autoload :TypedStruct,  'epitools/typed_struct'
autoload :Sys,          'epitools/sys'
autoload :SemanticVersion, 'epitools/semantic_version'

autoload :Matrix, 'epitools/core_ext/matrix'
autoreq(:Vector) { Matrix }

## Bundled slop
module Epi
  autoload :Slop, 'epitools/slop'
end
autoreq(:Slop) do 
  Slop = Epi::Slop
end

## Gems (common)

autoreq  :Mechanize,    'mechanize'
autoreq  :HTTP,         'http'

autoreq  :Nokogiri,     'nokogiri'
autoreq  :Oga,          'oga'
autoreq  :Ox,           'ox'

autoreq  :ANSI,         'ansi'

autoreq  :BSON,         'bson'
autoreq  :JSON,         'json'
autoreq  :BEncode,      'bencode'

autoreq  :GeoIP,        'geoip'

autoreq  :RBTree,       'rbtree'
autoreq  :MultiRBTree,  'rbtree'

autoreq  :ID3Tag,       'id3tag'

autoreq :Numo do
  require 'numo/narray'
end

autoreq :AwesomePrint do
  require 'awesome_print'

  autoreq :Nokogiri do
    require 'nokogiri'
    require 'awesome_print/ext/nokogiri'
  end
end

autoreq :CGI do
  require 'cgi'

  class CGI
    @@accept_charset = "UTF-8" unless defined? @@accept_charset
  end
end

## YAML hacks (the module might not be loaded properly in older Rubies)

if defined? YAML and not defined? YAML.parse
  del YAML  # remove the existing module
end
autoreq :YAML, 'yaml'
