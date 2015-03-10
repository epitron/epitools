## Standard library

autoload :Set,        'set'
autoload :URI,        'uri'
autoload :CGI,        'cgi'
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
autoload :CSV,        'csv'
autoload :Shellwords, 'shellwords'
autoload :Matrix,     'epitools/core_ext/matrix'

module Digest
  autoload :SHA1,     'digest/sha1'
  autoload :SHA2,     'digest/sha2'
  autoload :MD5,      'digest/md5'
end

# Network Sockets
['IP', 'Basic', 'TCP', 'UDP', 'UNIX', ''].each do |type|
  autoload :"#{type}Socket", 'socket'
end

# Network Servers
['TCP', 'UNIX'].each do |type|
  autoload :"#{type}Server", 'socket'
end

if RUBY_VERSION["1.8.7"]
  autoload :Prime,      'mathn'
else
  autoload :Prime,      'prime'
end


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


## Gems (common)

autoreq  :Nokogiri,     'nokogiri'
autoreq  :Mechanize,    'mechanize'
autoreq  :ANSI,         'ansi'
autoreq  :BSON,         'bson'
autoreq  :JSON,         'json'
autoreq  :GeoIP,        'geoip'

autoreq :AwesomePrint do
  require 'awesome_print'

  autoreq :Nokogiri do
    require 'nokogiri'
    require 'awesome_print/ext/nokogiri'
  end
end

## YAML hacks (sometimes the module is loaded improperly)

if defined? YAML and not defined? YAML.parse
  del YAML  # remove the existing module
end
autoreq :YAML, 'yaml'
