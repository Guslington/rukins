require 'yaml'

module Rukins
  class Utils
    class << self

      def load_default_params
        load_yml('config/default_params.yml')
      end

      def load_template_params
        load_yml('config/templates.yml')
      end

      def templates_config_exists
        File.exist?('config/templates.yml')
      end

      private

      def load_yml(file)
        abort "ERROR: unable to locate #{file}" unless File.exist?(file)
        YAML.load(File.open(file))
      end

    end
  end
end