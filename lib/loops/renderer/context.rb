class Loops
  class Renderer
    class Context
      attr_accessor :tags
      attr_accessor :object
      delegate_missing_to :@object

      def initialize(object:, tags:)
        @object = object
        @tags = tags
      end

      def get_binding
        binding
      end
    end
  end
end