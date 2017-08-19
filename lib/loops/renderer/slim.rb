require 'slim'

class Loops
  class Renderer
    class Slim < Loops::Renderer::Base
      register_extensions :slim

      def self.render(context:, filename:)
        ::Slim::Template.new(filename).render(context)
      end
    end
  end
end

Slim::Engine.set_options(use_html_safe: true)
