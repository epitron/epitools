gem_version = File.read("VERSION").strip

task :build do
  system "gem build .gemspec"
end

task :release => :build do
  system "gem push epitools-#{gem_version}.gem"
end

task :install => :build do
  system "gem install --user epitools-#{gem_version}.gem"
end

task :pry do
  system "pry --gem"
end

task :spec do
  cmd = %w[rspec --format documentation --force-color --pattern spec/*_spec.rb]
  cmd.unshift "rescue" if system *%w[which rescue]

  p cmd
  system *cmd
end

task :default => :spec
