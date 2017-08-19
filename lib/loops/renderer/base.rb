class Loops
  class Renderer
    class Base
      def self.render(context:, filename:)
        raise StandardError, 'Not implemented'
      end

      def self.register_extensions(*extensions)
        extensions.each do |extension|
          Loops::Renderer::register_extension(extension.to_sym, self)
        end
      end
    end
  end
end