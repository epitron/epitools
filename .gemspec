# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "epitools"
  s.version = File.read("VERSION").strip
  s.date = File.mtime("VERSION").strftime("%Y-%m-%d")

  s.authors = ["epitron"]
  s.description = "Miscellaneous utility libraries to make my life easier."
  s.email = "chris@ill-logic.com"
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc",
    "TODO"
  ]
  s.files = `git ls`.lines.map(&:strip)
  s.homepage = "http://github.com/epitron/epitools"
  s.licenses = ["WTFPL"]
  s.require_paths = ["lib"]
  s.summary = "Not utils... METILS!"

  if s.respond_to? :specification_version
    s.specification_version = 3
  end

  s.add_development_dependency "rspec", "~> 2"
  #s.add_dependency "mechanize",     "~> 1.0.0"
  #s.add_dependency "sqlite3-ruby",  ">= 0"
end

