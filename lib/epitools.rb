class Object

  unless defined?(__DIR__)
    # 
    # This method is convenience for the `File.expand_path(File.dirname(__FILE__))` idiom.
    # (taken from Michael Fellinger's Ramaze... thanx, dood! :D)
    #
    def __DIR__(*args)
      filename = caller[0][/^(.*):/, 1]
      dir = File.expand_path(File.dirname(filename))
      ::File.expand_path(::File.join(dir, *args.map{|a| a.to_s}))
    end
  end
  
end

require_wrapper = proc do |mod|
  begin
    require File.join(__DIR__, "epitools", mod)
  rescue LoadError => e
    puts "* Error loading epitools/#{mod}: #{e}"
  end
end

%w[
  metaclass 
  basetypes 
  niceprint
  string_to_proc
  ratio
  path
  zopen
  colored
  clitools
].each do |mod|
  require_wrapper.call mod
end
