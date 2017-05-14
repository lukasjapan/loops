#require_relative 'loops/object'

class Loops
  VERSION = '0.0.1-dev'
  
  def initialize
    @services = {}
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
    @services[method_name].call
  end
  
  class << self
    # Delegate call to a singleton Loops instance
    def method_missing(method_name, *arguments, &block)
      @loops ||= Loops.new
      @loops.send(method_name, *arguments, &block)
    end
  end
end

Loops.register_service(name: 'meh', service: "Test")
Loops.register_service(name: 'meh2', service: String)
Loops.register_service(name: 'meh3', service: String, shared: true)
Loops.register_service(name: 'time') { (1..50).to_a.sample }
Loops.register_service(name: 'ftime', shared: true) { (1..50).to_a.sample }
puts Loops.meh.inspect
puts Loops.meh2.inspect
puts Loops.meh3.inspect
puts Loops.time.inspect
puts Loops.time.inspect
puts Loops.ftime.inspect
puts Loops.ftime.inspect