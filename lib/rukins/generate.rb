require 'fileutils'

require 'rukins/cfndsl/cfngenerator'
require 'rukins/core/utils'
require 'rukins/core/rukinsfile'

module Rukins
  class Generate

    def initialize(options)
      @options = options
    end

    def run

      Rukins::Rukinsfile.new

      if Rukins::Utils.templates_config_exists
        templates_params = Rukins::Utils.load_template_params
        files = templates_from_config(templates_params["templates"])
      else
        templates = Dir["templates/**/*.rb",".templates/**/*.rb"]
        files = all_templates_in_directory(templates)
      end

      extras = get_extras(@options.cf_version)
      generate(@options.verbose,@options.cf_version,files,extras)
    end

    private

    def templates_from_config(templates)
      templates.each do |template|
        template["filename"] = "templates/" + template["filename"].to_s
        template["output"] = "output/" + template["output"].to_s
      end
    end

    def all_templates_in_directory(templates)
      files = []
      templates.each do |template|
        filename = "#{template}"
        output = template.slice(template.index("/")..-1)[1..-1]
        output = output.sub! '.rb', '.json'
        files << { filename: filename, output: "output/#{output}" }
      end
      return files
    end

    def get_extras(cf_version)
      extra_files = Dir['config/*.yml']
      extras = []
      extra_files.each do |extra|
        extras << [:yaml, extra]
      end
      extras << [:raw, "cf_version='#{cf_version}'"]
    end

    def generate(verbose,pretty,files,extras)
      puts "INFO: Generating JSON templates"
      Rukins::CfnGenerator.new do |t|
        t.cfndsl_opts = {
          verbose: verbose,
          pretty: pretty,
          files: files,
          extras: extras,
        }
      end
    end

  end
end
