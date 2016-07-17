require 'json'

class Config
  attr_reader :data

  def initialize(config_name)
    @config_name = config_name

    @data = {}
  end

  def load
    @data.clear

    if File.exist?(@config_name)
      File.open(@config_name, 'r') do |file|
        @data = JSON.load(file)
      end
    end

  end

  def save(data=nil)
    if data
      @data = data

      File.open(@config_name, 'w') do |file|
        file.write JSON.pretty_generate(@data)
      end
    end
  end
end