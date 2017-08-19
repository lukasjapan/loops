class Loops
  # @todo tag namespace is probably polluted very fast, at least separate classes from tags
  class Renderer
    @@renderer = {}

    def initialize(env_tags:, view_dirs:)
      @env_tags = env_tags.map(&:to_sym)
      @view_dirs = view_dirs
    end

    def render(object, tags: [])
      Loops.logger.debug{"Looking for a template of {#{object.class.name}} with preferred tags: [#{tags.join(', ')}]"}
      template = select_template(object: object, tags: tags.map(&:to_sym))

      raise "Template not found for class: #{object.class.name}, tags: #{tags}" unless template

      Loops.logger.debug{"Found template: #{template}"}

      template_output(object, template, tags: tags)
    end

    def self.register_extension(extension, render_class)
      @@renderer[extension] = render_class
    end

    private

    def template_output(object, template, tags: [], child_context: nil)
      raise 'Unknown extension' unless @@renderer.key?(template.extension)

      context = Loops::Renderer::Context.new(object: object, tags: tags, child_context: child_context)
      result = @@renderer[template.extension].render(context: context, filename: template.filename)
      return result unless context.extending

      template = select_template_from_file(context.extending)
      raise "Template file not found: #{context.extending}" unless template

      Loops.logger.warn("Stray output in child template #{template.filename}: #{result}") unless result.strip.blank?
      template_output(object, template, tags: tags, child_context: context)
    end

    # @todo Make this performant (Tree struct? Cache?)
    def select_template(object:, tags:)
      # get all classnames that can be used with templates
      target = object.is_a?(::Object) ? object.class : object
      names = target.ancestors.select { |a| a.is_a?(Class) }.map(&:to_s).map(&:underscore).map(&:to_sym)
      names.push(:class) if object.is_a?(Class)

      # Classnames > Environment > Required tags
      all_tags = names + @env_tags + tags

      all_templates.select do |template|
        # tags of filename must be all present and in correct order
        (template.tags & all_tags) == template.tags
      end.max_by do |template|
        # earlier tags will have higher priority
        all_tags.map { |t| template.tags.include?(t) ? 1 : 0 }.join
      end
    end

    def select_template_from_file(filename)
      all_templates.find do |template|
        template.filename_short == filename
      end
    end

    # @todo Make this performant (Tree struct? Cache?)
    def all_templates
      @templates ||= @view_dirs.map do |dir|
        Dir["#{dir}#{File::SEPARATOR}**#{File::SEPARATOR}*"].reject { |f| File.directory?(f) }.map do |filename|
          tags = filename[dir.length + 1, filename.length].split('.').map(&:to_sym)
          extension = tags.pop
          filename_short = tags.join('.')

          # a template definition
          OpenStruct.new(
              filename: filename,
              filename_short: filename_short,
              tags: tags,
              extension: extension
          )
        end
      end.flatten
    end
  end
end
