require 'rack'
require 'rack/handler/puma'

class Loops
  class Web
    def initialize
      @page = nil
    end

    def start
      Rack::Handler::Puma.run(self)
    end

    def call(env)
      request = Rack::Request.new(env)

      Loops.logger.info("----- A new web request has arrived! -----")
      Loops.logger.info("#{request.request_method} #{request.fullpath}")
      Loops.logger.info("------------------------------------------")

      result = Loops.path.resolve(path: request.path) { |type, object, param| self.send(type, object, param) }

      display = request.xhr? ? result : @page

      if(result)
        response = Rack::Response.new(Loops.renderer.render(@page))
      else
        response = Rack::Response.new(Loops.renderer.render(nil), 404)
      end

      Loops.logger.info("----- Done -----")

      response
    end

    private

    def pre_resolve(object, path)
    end

    def post_resolve(object, path)
    end

    def pre_call(object, args)
    end

    def post_call(object, result)
      @page = result if object.nil?
    end
  end
end
