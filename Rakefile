VERSION = File.read("VERSION").strip

task :build do
  system "gem build .gemspec"
end
 
task :release => :build do
  system "gem push epitools-#{VERSION}"
end
