require 'common/console_site'
require_relative 'audioboo_service'

class AudiobooSite < ConsoleSite
  attr_reader :service

  def initialize
    @service = AudiobooService.new

    super
  end

  def search(query:, page: 1, page_size: 12)
    response = service.search(query.join(' '))

    search_loop(response, query: query, page: page, page_size: page_size)
  end

  def get_download_url url
    service.get_playlist_urls(url)[0]
  end

  def get_download_list(type:, url:)
    service.get_audio_tracks(url)
  end

  def get_number(index, _, _)
    index+1
  end

  def navigate
    puts 'navigate'
  end
end
