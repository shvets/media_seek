require "highline/import"

require_relative 'utils'
require_relative 'site'
require 'common/downloader'

class ConsoleSite
  include Utils

  attr_reader :terminal, :downloader

  def initialize
    @terminal = HighLine.new
    @downloader = Downloader.new
  end

  def search_loop(items, query:, page:, page_size:)
    with_loop do
      items.each_with_index do |item, index|
        number = get_number(index, page, page_size)

        terminal.say(number.to_s + ". " + item[:name])
      end

      if get_number(page, 0, page_size) > page_size
        terminal.say("p. Prev Page")
      end

      if items.size == page_size
        terminal.say("n. Next Page")
      end

      terminal.say("x. Exit")

      with_interrupt_handler do
        choice = terminal.ask("Select index: ")

        if choice == 'x'
          true
        elsif choice == 'n'
          search(query: query, page: page+1)
        elsif choice == 'p' and page > 1
          search(query: query, page: page-1)
        elsif choice.match(/^(\d)+$/)
          number = choice.to_i

          puts number
          puts items.size

          item = items[number % page_size -1]

          if item[:type] == 'book'
            select_book(item)
          elsif item[:type] == 'movie'
            select_movie(item)
          elsif item[:type] == 'serie'
            select_serie(item)
          else
            select_item(item)
          end
        end
      end
    end
  end

  def select_book item
    with_loop do
      terminal.say("l. List")
      terminal.say("d. Download")
      terminal.say("x. Back")

      with_interrupt_handler do
        choice = terminal.ask("Select action: ")

        if choice == 'x'
          true
        elsif choice == 'l'
          download_list = get_download_list(type: item[:type], url: item[:path])

          puts "Book: " + item[:name]
          puts "Tracks: "

          puts JSON.pretty_generate(download_list)
        elsif choice == 'd'
          download_list = get_download_list(type: item[:type], url: item[:path])

          downloader.download_book(book_name: item[:name], tracks: download_list)
        end
      end
    end
  end

  def select_movie item
    with_loop do
      terminal.say("l. List")
      terminal.say("d. Download")
      terminal.say("x. Back")

      with_interrupt_handler do
        choice = terminal.ask("Select action: ")

        if choice == 'x'
          true
        elsif choice == 'l'
          download_list = get_download_list(type: item[:type], url: item[:path])

          puts "Movie: " + item[:name]
          puts "Tracks: "

          puts JSON.pretty_generate(download_list)
        elsif choice == 'd'
          download_list = get_download_list(type: item[:type], url: item[:path])

          item = download_list[0]

          downloader.download_movie(url: item[:url], name: item[:name])
        end
      end
    end
  end

  def select_serie serie
    with_loop do
      items = get_download_list(type: serie[:type], url: serie[:path])

      items.each_with_index do |item, index|
        number = get_number(index, 0, 0)

        terminal.say(number.to_s + ". " + item[:comment])
      end

      terminal.say("x. Back")

      with_interrupt_handler do
        choice = terminal.ask("Select action: ")

        if choice == 'x'
          true
        elsif choice.match(/^(\d)+$/)
          number = choice.to_i

          item = items[number-1]

          select_season serie[:name], item
        end
      end
    end
  end

  def select_season serie_name, season
    with_loop do
      terminal.say("l. List")
      terminal.say("d. Download")
      terminal.say("x. Back")

      with_interrupt_handler do
        choice = terminal.ask("Select action: ")

        if choice == 'x'
          true
        elsif choice == 'l'
          puts "Season: " + season[:comment]
          puts "Tracks: "

          puts JSON.pretty_generate(season[:playlist])
        elsif choice == 'd'
          downloader.download_season serie_name: serie_name, season_name: season[:comment], playlist: season[:playlist]
        end
      end
    end
  end

  def select_item item
    with_loop do
      terminal.say("l. List")
      terminal.say("d. Download")
      terminal.say("x. Back")

      with_interrupt_handler do
        choice = terminal.ask("Select action: ")

        if choice == 'x'
          true
        elsif choice == 'l'
          download_list = get_download_list(type: item[:type], url: item[:path])

          puts "Item: " + item[:name]
          puts "Tracks: "

          puts JSON.pretty_generate(download_list)
        elsif choice == 'd'
          url = get_download_url(item[:path])

          download_item(url: url, name: item[:name], is_serie: item[:is_serie])
        end
      end
    end
  end

  def get_number(index, _, _)
    index+1
  end

  def get_download_url url
    url
  end

end