require 'common/console_site'
require_relative 'hdserials_service'

class HDSerialsSite < ConsoleSite
  attr_reader :service

  def initialize
    @service = HDSerialsService.new

    super
  end

  def search(query:, page: 1, page_size: 12)
    response = service.search(query.join(' '), page: page)

    search_loop(response[:items], query: query, page: page, page_size: page_size)
  end

  def get_download_list(type:, url:)
    puts url

    # if type == 'serie'
    #   service.get_serie_info(url)
    # elsif ['movie', 'epispde'].include? type
    service.retrieve_urls(url)
    # end
  end

  def navigate
    puts 'navigate'
  end
end