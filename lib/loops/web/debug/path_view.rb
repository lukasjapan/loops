class Loops
  class Web
    class Debug
      class PathView
        attr_accessor :paths
        attr_accessor :flattened_paths

        def initialize(object = NilClass, recursion = [])
          @paths = Loops.path.instance_variable_get(:@paths)[object].map do |type, matchers|
            matchers.map do |matcher, proc, klass|
              path = case matcher
              when Loops::Path::ExactMatcher
                matcher.instance_variable_get(:@exact_string)
              when Loops::Path::StringMatcher
                matcher.instance_variable_get(:@string)
              when Loops::Path::RegexpMatcher
                matcher.instance_variable_get(:@regexp).to_s
              end

              child_path_view = self.class.new(klass, recursion + [ object ]) unless recursion.include?(klass)

              [ [ type, path ], [ klass, child_path_view ] ]
            end.to_h
          end.reduce({}, :merge)

          @flattened_paths = _flattened_paths(@paths)
        end

        private

        def _flattened_paths(paths, prefix = [])
          paths.each_pair.reduce({}) do |a, (k, v)|
            new_prefix = prefix + [ k ]
            a.merge!(new_prefix => v[0])
            a.merge!(_flattened_paths(v[1].paths, new_prefix))
          end
        end
      end
    end
  end
end
