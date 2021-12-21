
module Oga
  module XML
    # Serialize this node to HAML
    module ElementToHAML
      def to_haml
        require 'html2haml'
        require 'html2haml/html'
        Html2haml::HTML.new(to_xml, {}).render.rstrip
      end
      alias_method :haml, :to_haml

      def pretty
        require 'coderay'
        puts CodeRay.scan(haml, :haml).term
      end
      #alias_method :pp, :pretty
    end

    module PrettyNodeSet
      def pretty
        require 'coderay'
        lesspipe(wrap: true) { |less| each { |node| less.puts CodeRay.scan(node.to_haml, :haml).term; less.puts; less.puts } }
      end
    end
 
  end
end

Oga::XML::Element.include Oga::XML::ElementToHAML
Oga::XML::NodeSet.include Oga::XML::PrettyNodeSet
