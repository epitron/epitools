require 'epitools/progressbar'

#
# Mechanize Progress Bar extension
#
# (Displays a progress bar whenever an url is retrieved.)
#
class Mechanize # :nodoc: all
  class Chain
    class ResponseReader
      include Mechanize::Handler

      def initialize(response)
        @response = response
      end

      def handle(ctx, params)
        params[:response] = @response
        body = StringIO.new
        total = 0

        if @response.respond_to? :content_type
          pbar = ProgressBar.new("  |_ #{@response.content_type}", @response.content_length)
        else
          pbar = nil
        end

        @response.read_body { |part|
          total += part.length
          body.write(part)

          pbar.set(total) if pbar
          Mechanize.log.debug("Read #{total} bytes") if Mechanize.log
        }

        pbar.finish if pbar

        body.rewind

        res_klass = Net::HTTPResponse::CODE_TO_OBJ[@response.code.to_s]
        raise ResponseCodeError.new(@response) unless res_klass

        # Net::HTTP ignores EOFError if Content-length is given, so we emulate it here.
        unless res_klass <= Net::HTTPRedirection
          raise EOFError if (!params[:request].is_a?(Net::HTTP::Head)) && @response.content_length() && @response.content_length() != total
        end

        @response.each_header { |k,v|
          Mechanize.log.debug("response-header: #{ k } => #{ v }")
        } if Mechanize.log

        params[:response_body] = body
        params[:res_klass] = res_klass
        super
      end
    end
  end
end
