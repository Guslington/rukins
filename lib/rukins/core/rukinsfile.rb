require 'rukins/core/templates'

module Rukins
  class Rukinsfile

    def initialize
      @path = "Rukinsfile"
      @template_directory = ".templates"
      File.exist?(@path) ? instance_eval(File.read(@path)) : puts("INFO: No rukinsfile detected")
    end

    def source(source)
      @source = source
    end

    def template(name, version = "latest", source = @source)
      abort("ERROR: No souce location supplied") if source == nil
      dot_template_directory(@template_directory)

      templ = Rukins::Templates.new(@source,@template_directory)

      puts "Fetching template metadata from #{source}"

      version = templ.get_template_version(name) if version == "latest"

      if !template_exists(name)
        puts "  Downloading template '#{name} (= #{version})'"
        templ.get_metadata(name,version)
        templ.get_template(name,version)
      else
        current_metadata = templ.get_current_metadata(template)
        current_version = current_metadata['version']
        if current_version != version
          puts "  Updating template #{name} #{version} from #{current_version}"
          templ.get_metadata(name,version)
          templ.get_template(name,version)
        end
      end
    end

    def dot_template_directory(directory)
      ::FileUtils.mkdir_p(directory) unless File.directory?(directory)
    end

    def template_exists(template)
      File.file?(template)
    end

  end
end
