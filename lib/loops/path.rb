class Loops
  class Path
    # special class that stops following the path
    class Stop; end

    # separators
    SEPARATOR = '/'

    def initialize
      # @type [Hash<Object,Array<Matcher,Proc>]
      @paths = Hash.new do |h, k|
        h[k] = {
            exact: [],        # like NGINX location = /foo matcher
            string: [],       # like NGINX location /foo matcher
            quickregexp: [],  # like NGINX location ^~ /foo matcher
            regexp: []        # like NGINX location ~ /foo matcher
        }
      end
    end

    def register(object:, path:, type:, exact: false, regexp: false, &block)
      raise ArgumentError, 'Block needs to be given when registering a path.' unless block_given?

      if path.is_a?(Regexp)
        key = :regexp
        matcher = RegexpMatcher.new(path)
      elsif exact
        key = :exact
        matcher = ExactMatcher.new(path.to_s)
      elsif regexp
        key = :quickregexp
        matcher = StringMatcher.new(path.to_s)
      else
        key = :string
        matcher = StringMatcher.new(path.to_s)
      end

      @paths[object][key].push([matcher, block, type])

      matcher
    end

    def resolve(object: nil, path:, data: nil, &block)
      # callback
      Loops.logger.debug{"Looking for something " + ("on object {#{object.class.name}} " if object).to_s +  "in '#{path}'"}
      yield(:pre_resolve, object, path) if block_given?

      matcher, proc = resolve_matcher(object, path)

      # return if nothing matched
      return unless matcher

      # callback
      matched_path = path[0, matcher.length]
      Loops.logger.debug{"Found something at " + ("{#{object.class.name}} " if object).to_s +  "'#{matched_path}'"}
      yield(:post_resolve, object, matched_path) if block_given?

      # remove the matched part from the path, also strip separators
      path = path[matcher.length, path.length].sub(/^#{Regexp.escape(SEPARATOR)}+/, '')

      # get arguments from matcher and merge other data
      args = matcher.args.merge({path: path, data: data})

      # callback
      Loops.logger.debug{"Retrieving " + ("{#{object.class.name}}" if object).to_s +  "'#{matched_path}'(#{args.inspect})"}
      yield(:pre_call, object, args) if block_given?

      # call associated block (in object context)
      result = object.instance_exec(args, &proc)

      # callback
      Loops.logger.debug{"Got a {#{result.class.name}}."}
      yield(:post_call, object, result) if block_given?

      # Stop is special, stop following the path
      return if result.is_a?(Stop)

      # if there is still path left, continue resolving
      path.empty? ? result : resolve(object: result, path: path, &block)
    end

    private

    def resolve_matcher(object, path)
      klass = object.is_a?(Class) ? object : object.class

      # no paths registered for this class
      return unless @paths.key?(klass)

      # Check for exact matches
      matcher, proc = @paths[klass][:exact].find do |matcher, _|
        matcher.match(path)
      end

      # exact matches are returned immediately
      return matcher, proc if matcher

      # find longest match
      matcher, proc = (@paths[klass][:string] + @paths[klass][:quickregexp])
          .select { |matcher, _| matcher.match(path) }
          .sort_by { |matcher, _| matcher.length }
          .last

      # if marked as regexp string, return immediately
      return matcher, proc if @paths[klass][:quickregexp].map(&:first).include?(matcher)

      # check regexps
      rmatcher, rproc = @paths[klass][:regexp].find do |matcher, _|
        matcher.match(path)
      end

      # regexps have precedence
      [rmatcher || matcher, rproc || proc]
    end

    class Matcher
      attr_accessor :length, :args

      def initialize
        @length = nil
        @args = nil
      end
    end

    class ExactMatcher < Matcher
      def initialize(string)
        @exact_string = string.to_s
        super()
      end

      def match(path)
        return false unless path == @exact_string
        @length = @string.length
        @args = {}
        true
      end
    end

    class StringMatcher < Matcher
      def initialize(string)
        @string = string
        super()
      end

      def match(path)
        return false unless path.start_with?(@string)
        @length = @string.length
        @args = {}
        true
      end
    end

    class RegexpMatcher < Matcher
      def initialize(regexp)
        @regexp = regexp
      end

      def match(path)
        m = @regexp.match(path)
        return false unless m && m.begin(0) == 0
        @length = m[0].length
        @args = {} # m.to_a.drop(1)
        true
      end
    end
  end

  module Pathable
    # Registers a path with the current object
    def path(path, type, constructor = :new, &block)
      proc = block_given? ? block : Proc.new { type.send(constructor) }
      Loops.path.register(object: self, path: path, type: type, &proc)
    end

    def root_path(path = Path::SEPARATOR, type = nil, constructor = :new, exact: false, regexp: false, &block)
      # use the passed block or create itself if none is given
      klass = self
      type = block_given? ? type : klass
      proc = block_given? ? block : Proc.new { klass.send(constructor) }
      Loops.path.register(object: NilClass, path: path, type: type, exact: exact, regexp: regexp, &proc)
    end

    def resolve_path(path:, data: nil)
      Loops.path.resolve(object: self, path: path, data: data)
    end
  end
end
