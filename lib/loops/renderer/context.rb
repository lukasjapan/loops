class Loops
  class Renderer
    class Context
      attr_accessor :tags
      attr_accessor :object
      attr_accessor :extending
      delegate_missing_to :@object

      def initialize(object:, tags:, child_context: nil)
        @object = object
        @tags = tags
        @extending = nil
        @child_context = child_context
        @blocks = {}
        @current_parent = nil
      end

      def get_binding
        binding
      end

      # TODO: include these by a module

      def extends(filename)
        raise "Already extending from template: #{@extending}" if @extending
        raise "Call extending before blocks." if @extending == false
        @extending = filename
      end

      def block(name, &block)
        raise "No block given." unless block_given?
        raise "Do not nest blocks." if @current_parent
        @blocks[name] = block
        @extending = false unless @extending
        resolve_block(name) if @extending == false
      end

      def render(object, tags = [])
        tags = [ tags ] unless tags.is_a?(Enumerable)
        Loops.renderer.render(object, tags: @tags + tags).html_safe
      end

      def parent
        raise "Please call from a block only." unless @current_parent
        @current_parent.call
      end

      def resolve_block(name, parent = nil)
        @current_parent = parent
        result = @child_context.resolve_block(name, @blocks[name] || parent) if @child_context
        result = @blocks[name].call if result.nil? && @blocks.key?(name)
        @current_parent = nil
        result.try(:html_safe)
      end
    end
  end
end
