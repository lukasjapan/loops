require 'rack'
require 'rack/handler/puma'

class Loops
  class Web
    def start
      Rack::Handler::Puma.run(self)
    end

    def call(env)
      request = Rack::Request.new(env)

      Loops.logger.info("----- A new web request has arrived! -----")
      Loops.logger.info("#{request.request_method} #{request.fullpath}")
      Loops.logger.info("------------------------------------------")

      begin
        result = Loops.path.resolve(path: request.path) # { |type, object, param| self.send(type, object, param) }
        display = request.xhr? ? result : select_page(result)

        status = result ? 200 : 404
        body = Loops.renderer.render(display)
      rescue => e
        status = 500
        puts e.class.name
        body = Loops.renderer.render(e)
      end

      response = Rack::Response.new(body, status)

      Loops.logger.info("----- Done -----")

      #response.content_type = "text/html"
      response
    end

    private

    def select_page(result)
      DefaultPage.new(result)
    end

    def pre_resolve(object, path)
    end

    def post_resolve(object, path)
    end

    def pre_call(object, args)
    end

    def post_call(object, result)
    end
  end
end
