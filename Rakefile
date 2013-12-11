gem_version = File.read("VERSION").strip

task :build do
  system "gem build .gemspec"
end
 
task :release => :build do
  system "gem push epitools-#{gem_version}.gem"
end

task :install => :build do
  system "gem install epitools-#{gem_version}.gem"
end

task :pry do
  system "pry --gem"
end
