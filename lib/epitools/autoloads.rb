## Standard library
autoload :Set,        'set'
autoload :URI,        'uri'
autoload :CGI,        'cgi'
autoload :Base64,     'base64'
autoload :JSON,       'json'
autoload :Zlib,       'zlib'
autoload :FileUtils,  'fileutils'
autoload :Tempfile,   'tempfile'
autoload :BigDecimal, 'bigdecimal'
autoload :StringIO,   'stringio'
autoload :Curses,     'curses'
autoload :DateTime,   'date'
autoload :Date,       'date'
autoload :Open3,      'open3'
autoload :Timeout,    'timeout'
autoload :Find,       'find'
autoload :Benchmark,  'benchmark'
#autoload :DelegateClass, 'delegate'

# YAML is sometimes loaded improperly.
if defined? YAML and not defined? YAML.parse
  del YAML  # remove the existing module
end

autoload :YAML, 'yaml'

if RUBY_VERSION["1.8.7"]
  autoload :Prime,      'mathn'
else
  autoload :Prime,      'prime'
end

module Digest
  autoload :SHA1,     'digest/sha1'
  autoload :SHA2,     'digest/sha2'
  autoload :MD5,      'digest/md5'
end

## Nonstandard library
autoload :Path,         'epitools/path'
autoload :Ezdb,         'epitools/ezdb'
autoload :Browser,      'epitools/browser'
autoload :Rash,         'epitools/rash'
autoload :Ratio,        'epitools/ratio'
autoload :Sys,          'epitools/sys'
autoload :ProgressBar,  'epitools/progressbar'
autoload :Trie,         'epitools/trie'
autoload :MimeMagic,    'epitools/mimemagic'
autoload :Term,         'epitools/term'
autoload :Iter,         'epitools/iter'

## Gems (common)
autoreq  :Nokogiri,     'nokogiri'
autoreq  :ANSI,         'ansi'
autoreq  :BSON,         'bson'
