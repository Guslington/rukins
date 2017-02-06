require 'net/http'

module Rukins
  class Templates

    def initialize(source,template_directory)
      @source = source
      @template_directory = template_directory
    end

    def get_template_version(template)
      metadata = get_latest_metadata(template)
      metadata["version"]
    end

    def get_latest_metadata(template)
      JSON.parse(get_request("#{@source}/#{template}/#{template}.json"))
    end

    def get_current_metadata(template)
      JSON.parse( IO.read("#{@template_directory}/#{template}.json") )
    end

    def get_metadata(template,version)
      File.open("#{@template_directory}/#{template}.json", 'w') {|f| f.write get_request("#{@source}/#{template}/#{version}/#{template}.json") }
    end

    def get_template(template,version)
      File.open("#{@template_directory}/#{template}.rb", 'w') {|f| f.write get_request("#{@source}/#{template}/#{version}/#{template}.rb") }
    end

    private

    def get_request(uri)
      uri = URI(uri)
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new uri
        response = http.request request
        case response
        when Net::HTTPOK
          response.body
        else
          raise "unable to make request"
        end
      end
    end

  end
end
