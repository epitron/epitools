if defined? Rails
  
  class ActiveRecord::Base
    def self.[](n)
      find n
    end
  end
  
end


