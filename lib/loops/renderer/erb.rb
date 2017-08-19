class Loops
  class Renderer
    class Erb < Loops::Renderer::Base
      register_extensions :erb, :htm, :html

      def self.render(context:, filename:)
        ERB.new(File.read(filename)).result(context.get_binding)
      end
    end
  end
end