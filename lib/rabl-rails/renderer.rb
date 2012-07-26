require 'rabl-rails/renderers/base'
require 'rabl-rails/renderers/json'

module RablRails
  module Renderer
    mattr_reader :view_path
    @@view_path = 'app/views'

    class LookupContext
      T = Struct.new(:source)

      def initialize(view_path, format)
        @view_path = view_path || RablRails::Renderer.view_path
        @format = format
      end

      #
      # Manually find given rabl template file with given format.
      # View path can be set via options, otherwise default Rails
      # path is used
      #
      def find_template(name, opt, partial = false)
        path = File.join(@view_path, "#{name}.#{@format}.rabl")
        File.exists?(path) ? T.new(File.read(path)) : nil
      end
    end

    #
    # Context class to emulate normal rendering view
    # context
    #
    class Context
      attr_reader :format
      attr_accessor :target_object

      def initialize(path, options)
        @virtual_path = path
        @format = options.delete(:format) || 'json'
        @_assigns = {}
        @options = options

        options[:locals].each { |k, v| @_assigns[k.to_s] = v } if options[:locals]
      end

      def assigns
        @_assigns
      end

      def params
        { format: format }
      end

      def lookup_context
        @lookup_context ||= LookupContext.new(@options[:view_path], format)
      end
    end
  
    #
    # Renders object with the given rabl template.
    # 
    # Object can also be passed as an option :
    # { locals: { object: obj_to_render } }
    #
    # Default render format is JSON, but can be changed via
    # an option: { format: 'xml' }
    #
    def render(object, template, options = {})
      object = options[:locals].delete(:object) if !object && options[:locals]

      c = Context.new(template, options)
      c.target_object = object

      t = c.lookup_context.find_template(template, [], false)

      Library.instance.get_rendered_template(t.source, c)
    end
  end
end