require 'inifile'

module ChefMetalAzure
  # Reads in a credentials file from a config file and presents them
  class Credentials
    
    AZURE_CONFIG_PATH = "#{ENV['HOME']}/.azure/config"
    
    def initialize
      @credentials = {}
      load_default
    end

    include Enumerable

    def default
      if @credentials.size == 0
        raise "No credentials loaded!  Do you have a #{AZURE_CONFIG_PATH}?"
      end
      @credentials[ENV['AZURE_DEFAULT_PROFILE'] || 'default'] || @credentials.first[1]
    end

    def keys
      @credentials.keys
    end

    def [](name)
      @credentials[name]
    end

    def each(&block)
      @credentials.each(&block)
    end

    def load_ini(credentials_ini_file)
      inifile = IniFile.load(File.expand_path(credentials_ini_file))
      if inifile
        inifile.each_section do |section|
          if section =~ /^\s*profile\s+(.+)$/ || section =~ /^\s*(default)\s*/
            profile_name = $1.strip
            profile = inifile[section].inject({}) do |result, pair|
              result[pair[0].to_sym] = pair[1]
              result
            end
            profile[:name] = profile_name
            @credentials[profile_name] = profile
          end
        end
      else
        # Get it to throw an error
        File.open(File.expand_path(credentials_ini_file)) do
        end
      end
    end

    
    def load_default
      config_file = ENV['AZURE_CONFIG_FILE'] || File.expand_path(AZURE_CONFIG_PATH)
      if File.file?(config_file)
        load_ini(config_file)
      end
    end

    def self.method_missing(name, *args, &block)
      singleton.send(name, *args, &block)
    end

    def self.singleton
      @azure_credentials ||= Credentials.new
    end
  end
end
