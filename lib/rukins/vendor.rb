module Rukins
  class Vendor

    def Initialize(template,otions)
      @options = options
      @template = template
    end

    def run
      templ = Rukins::Templates.new("http://templates.gusvine.me","templates")
      version = (@options[:version] ? @options[:version] : templ.get_template_version(template))
      templ.get_template(@template,version)
    end

  end
end
