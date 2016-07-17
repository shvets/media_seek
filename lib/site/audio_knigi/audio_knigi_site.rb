require 'common/console_site'
require_relative 'audio_knigi_service'

require 'common/downloader'

class AudioKnigiSite < ConsoleSite
  attr_reader :service

  def initialize
    @service = AudioKnigiService.new

    super
  end

  def search(query:, page: 1, page_size: 12)
    response = service.search(query.join(' '), page)

    search_loop(response[:items], query: query, page: page, page_size: page_size)
  end

  def get_download_list(type:, url:)
    service.get_audio_tracks(url)
  end

  def get_number index, page, page_size
    (page.to_i-1)*page_size +(index+1)
  end

  def navigate
    with_loop do
      terminal.say("1. Authors")
      terminal.say("2. Performers")
      terminal.say("x. Exit")

      with_interrupt_handler do
        choice = terminal.ask("Choose item: ")

        if choice == 'x'
          true
        elsif choice.match(/^(\d)+$/)
          if choice == '1'
            get_authors
          elsif choice == '2'
            get_performers
          end
        end
      end
    end
  end

  def get_authors
    authors = load_list "authors.json"

    letters = @service.get_authors_letters

    with_loop do
      letters.each_with_index do |letter, index|
        terminal.say((index+1).to_s + ". " + letter)
      end

      terminal.say("x. Back")

      with_interrupt_handler do
        choice = terminal.ask("Choose letter: ")

        if choice == 'x'
          true
        elsif choice.match(/^(\d)+$/)
          select_letter(letters[choice.to_i-1], authors)
        end
      end
    end
  end

  def select_letter letter, authors
    if letter == "Все"
      response = service.get_authors(page: 1)

      response['items'].each do |item|
        select_author(url: item[:path], name: item[:name])
      end
    else
      select_authors_letters letter, authors
    end
  end

  def select_authors_letters letter, authors
    with_loop do
      done = false

      until done do
        index = 0

        groups = []

        authors.each do |group_name, group|
          if group_name.index(letter) == 0
            terminal.say((index+1).to_s + ". " + group_name)
            groups << group
            index = index+1
          end
        end

        terminal.say("x. Back")

        with_interrupt_handler do
          choice = terminal.ask("Select prefix:")

          if choice == 'x'
            true
          elsif choice.match(/^(\d)+$/)
            select_author_letter(groups[choice.to_i-1])
          end
        end
      end
    end
  end

  def select_author_letter group
    with_loop do
      terminal.say("x. Back")

      group.each_with_index do |item, index|
        terminal.say((index+1).to_s + ". " + item[:name])
        #menu.choice(item[:name]) { select_author(url: item[:path], name: item[:name]) }
      end

      with_interrupt_handler do
        choice = terminal.ask("Select author:")

        if choice == 'x'
          true
        elsif choice.match(/^(\d)+$/)
          item = group[choice.to_i-1]

          select_author(url: item[:path], name: item[:name])
        end
      end
    end
  end

  def select_author(url:, name:, page: 1)
    response = service.get_books(path: url, page: page)

    books = response[:items]

    with_loop do
      books.each_with_index do |book, index|
        terminal.say(page_index(page, index, 12).to_s + ". " + book[:name])
      end

      if page_index(page, 0, page_size) > page_size
        terminal.say("p. Prev Page")
      end

      if books.size == page_size
        terminal.say("n. Next Page")
      end

      terminal.say("x. Back")

      with_interrupt_handler do
        choice = terminal.ask(name + ": Select book index: ")

        if choice == 'x'
          true
        elsif choice == 'n'
          select_author(url: url, name: name, page: page+1)
        elsif choice == 'p' and page > 1
          select_author(url: url, name: name, page: page-1)
        elsif choice.match(/^(\d)+$/)
          number = choice.to_i

          book = books[number-1]

          select_book(book)
        end
      end
    end
  end

  def get_performers
    performers = load_list "lib/performers.json"
  end

  protected

  def load_list file_name
    content = JSON.parse(File.open(file_name).read)

    service.group_items_by_letter(content)
  end
end
