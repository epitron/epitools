# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "epitools"
  s.version = "0.5.10"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["epitron"]
  s.date = "2012-08-26"
  s.description = "Miscellaneous utility libraries to make my life easier."
  s.email = "chris@ill-logic.com"
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc",
    "TODO"
  ]
  s.files = [
    ".document",
    "Guardfile",
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "TODO",
    "VERSION",
    "epitools.gemspec",
    "lib/epitools.rb",
    "lib/epitools/autoloads.rb",
    "lib/epitools/browser.rb",
    "lib/epitools/browser/cache.rb",
    "lib/epitools/browser/mechanize_progressbar.rb",
    "lib/epitools/clitools.rb",
    "lib/epitools/colored.rb",
    "lib/epitools/core_ext.rb",
    "lib/epitools/core_ext/array.rb",
    "lib/epitools/core_ext/enumerable.rb",
    "lib/epitools/core_ext/hash.rb",
    "lib/epitools/core_ext/misc.rb",
    "lib/epitools/core_ext/numbers.rb",
    "lib/epitools/core_ext/object.rb",
    "lib/epitools/core_ext/string.rb",
    "lib/epitools/core_ext/truthiness.rb",
    "lib/epitools/ezdb.rb",
    "lib/epitools/hexdump.rb",
    "lib/epitools/iter.rb",
    "lib/epitools/its.rb",
    "lib/epitools/lcs.rb",
    "lib/epitools/mimemagic.rb",
    "lib/epitools/mimemagic_tables.rb",
    "lib/epitools/minimal.rb",
    "lib/epitools/niceprint.rb",
    "lib/epitools/numwords.rb",
    "lib/epitools/path.rb",
    "lib/epitools/permutations.rb",
    "lib/epitools/pretty_backtrace.rb",
    "lib/epitools/progressbar.rb",
    "lib/epitools/rails.rb",
    "lib/epitools/rash.rb",
    "lib/epitools/ratio.rb",
    "lib/epitools/sys.rb",
    "lib/epitools/term.rb",
    "lib/epitools/trie.rb",
    "lib/epitools/typed_struct.rb",
    "lib/epitools/wm.rb",
    "lib/epitools/zopen.rb",
    "spec/autoreq_spec.rb",
    "spec/browser_spec.rb",
    "spec/clitools_spec.rb",
    "spec/colored_spec.rb",
    "spec/core_ext_spec.rb",
    "spec/ezdb_spec.rb",
    "spec/iter_spec.rb",
    "spec/lcs_spec.rb",
    "spec/numwords_spec.rb",
    "spec/path_spec.rb",
    "spec/permutations_spec.rb",
    "spec/rash_spec.rb",
    "spec/ratio_spec.rb",
    "spec/spec.opts",
    "spec/spec_helper.rb",
    "spec/sys_spec.rb",
    "spec/term_spec.rb",
    "spec/typed_struct_spec.rb",
    "spec/wm_spec.rb",
    "spec/zopen_spec.rb"
  ]
  s.homepage = "http://github.com/epitron/epitools"
  s.licenses = ["WTFPL"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "NOT UTILS... METILS!"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, ["~> 2.2.0"])
      s.add_development_dependency(%q<mechanize>, ["~> 1.0.0"])
      s.add_development_dependency(%q<sqlite3-ruby>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, ["~> 2.2.0"])
      s.add_dependency(%q<mechanize>, ["~> 1.0.0"])
      s.add_dependency(%q<sqlite3-ruby>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, ["~> 2.2.0"])
    s.add_dependency(%q<mechanize>, ["~> 1.0.0"])
    s.add_dependency(%q<sqlite3-ruby>, [">= 0"])
  end
end

