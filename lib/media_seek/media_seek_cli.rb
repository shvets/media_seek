require "thor"
require "media_seek/version"
require "media_seek/main"

class MediaSeekCLI < Thor
  def initialize *params
    super

    @main = MediaSeek::Main.new options['site']
  end

  class_option :site, type: :string, default: 'audioknigi', :aliases => "-s"

  desc "version", "displays version"
  def version
    puts "Media Seek Version: #{MediaSeek::VERSION}"
  end

  desc "search", "search for media"
  def search(*query)
    @main.search(query: query)
  end

  desc "navigate", "navigate"
  def navigate
    @main.navigate
  end
end