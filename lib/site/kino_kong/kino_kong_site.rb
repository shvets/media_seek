require 'common/console_site'
require_relative 'kino_kong_service'

class KinoKongSite < ConsoleSite
  attr_reader :service

  def initialize
    @service = KinoKongService.new

    super
  end

  def search(query:, page: 1, page_size: 12)
    response = service.search(query.join(' '), page: page, page_size: page_size)

    search_loop(response[:items], query: query, page: page, page_size: page_size)
  end

  def get_download_list(type:, url:)
    if type == 'serie'
      service.get_serie_info(url)
    elsif ['movie', 'epispde'].include? type
      service.get_urls(url)
    end
  end

  def navigate
    puts 'navigate'
  end
end
