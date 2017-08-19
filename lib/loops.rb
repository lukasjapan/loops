class Loops
  def initialize(tags: [])
    @services = {}

    register_service(name: :renderer, service: Renderer.new(env_tags: tags, view_dirs: %w(views/web/bootstrap4)))
    register_service(name: :path, service: Path.new)
    register_service(name: :logger, service: Logger.new(STDERR))
  end

  def register_service(name:, service: nil, shared: nil, &block)
    raise ArgumentError, 'Please pass service or block' unless !!service ^ block_given?

    shared ||= service && !service.is_a?(Class)

    if block_given?
      proc = shared ? Proc.new { service ||= block.call } : block
    else
      proc = Proc.new { shared ? service : service.new }
    end

    @services[name.to_sym] = proc
  end

  def method_missing(method_name, *arguments, &block)
    raise StandardError, "Service '#{method_name}' not found." unless @services.key?(method_name)
    @services[method_name].call(*arguments, &block)
  end

  class << self
    # Delegate call to a singleton Loops instance
    def method_missing(method_name, *arguments, &block)
      @loops ||= Loops.new
      @loops.send(method_name, *arguments, &block)
    end
  end
end
