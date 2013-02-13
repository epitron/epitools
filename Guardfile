# A sample Guardfile
# More info at https://github.com/guard/guard#readme

#guard 'spork', :wait => 50 do
#  watch('Gemfile')
#  watch('Gemfile.lock')
#  watch('spec/spec_helper.rb')
#end

guard :rspec, :version => 2, :cli => "--color", :bundler => false, :all_after_pass => false, :all_on_start => false, :keep_failed => false do
#guard 'rspec', :version => 2 do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/epitools/([^/]+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^lib/epitools/([^/]+)/.+\.rb$})  { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')              { "spec" }
end

