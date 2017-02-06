require 'thor'

module Rukins
  class New < Thor::Group

    include Thor::Actions

    def initialize(project,options)
      @project = project
      @options = options
    end

    def self.source_root
      File.dirname(__FILE__)
    end

    def new_project
      abort "ERROR: #{@project} already exists" if Dir.exist?(@project)
      puts "INFO: Creating new project #{@project}"
      self.destination_root = Dir.pwd
      directory 'newproject', @project
    end

  end
end
