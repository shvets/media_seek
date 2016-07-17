require 'uri'
require 'ruby-progressbar'

require 'common/http_service'

class AudioKnigiService < HttpService
  URL = 'https://audioknigi.club'

  def get_page_path path, page=1
      "#{path}page#{page}/"
  end

  def get_authors_letters
    get_letters(path: '/authors/', filter: 'author-prefix-filter')
  end

  def get_performers_letters
    get_letters(path: '/performers/', filter: 'performer-prefix-filter')
  end

  def get_letters(path:, filter:)
    data = []

    document = fetch_document(url: URL + path, encoding: 'utf-8')

    items = document.xpath('//ul[@id="' + filter + '"]/li/a')

    items.each do |item|
      name = item.content

      data << name
    end

    data
  end

  def get_new_books page: 1
    get_books(path: '/index/', page: page)
  end

  def get_best_books period:, page:1
    get_books(path:'/index/views/', period: period, page: page)
  end

  def get_books path:, period: nil, page: 1
    path = URI.decode(path)

    page_path = get_page_path(path, page)

    if period
        page_path = page_path + "?period=" + period
    end

    document = fetch_document(url: URL + page_path, encoding: 'utf-8')

    get_book_items(document, path=path, page=page)
  end

  def get_book_items document, path, page
    data = []

    items = document.xpath('//article')

    items.each do |item|
      link = item.xpath('header/h3/a').first

      name = link.content
      href = link.xpath('@href').text
      thumb = item.xpath('img').attr('src').text
      description = item.xpath('div[@class="topic-content text"]').children.first.content.strip

      data << {'type': 'book', 'name': name, 'path': href, 'thumb': thumb, 'description': description}
    end

    pagination = extract_pagination_data(document: document, path: path, page: page)

    {'items': data, 'pagination': pagination}
  end

  def get_authors page: 1
    get_collection(path: '/authors/', page: page)
  end

  def get_performers page: 1
    get_collection(path: '/performers/', page: page)
  end

  def get_collection path:, page: 1
    data = []

    page_path = get_page_path(path, page)

    document = fetch_document(url: URL + page_path, encoding: 'utf-8')

    items = document.xpath('//td[@class="cell-name"]')

    items.each do |item|
      link = item.xpath('h4/a').first

      name = link.text
      href = link.attr('href')[URL.length..-1] + '/'

      data << {'name': name, 'path': URI.decode(href)}
    end

    pagination = extract_pagination_data(document: document, path: path, page: page)

    {'items': data, 'pagination': pagination}
  end

  def get_genres page: 1
    data = []

    path = '/sections/'

    page_path = get_page_path(path, page)

    document = fetch_document(url: URL + page_path, encoding: 'utf-8')

    items = document.xpath('//td[@class="cell-name"]')

    items.each do |item|
      link = item.xpath('a').first

      name = item.xpath('h4/a').first.text
      href = link.attr('href')[URL.length]
      thumb = link.xpath('img').attr('src')

      data << {'name': name, 'path': href, 'thumb': thumb}
    end

    pagination = extract_pagination_data(document: document, path: path, page: page)

    {'items': data, 'pagination': pagination}
  end

  def get_genre(path:, page: 1)
    get_books(path: path, page: page)
  end

  def extract_pagination_data(document:, path:, page:)
    pages = 1

    pagination_root = document.xpath('//div[@class="paging"]')

    if pagination_root and pagination_root.length > 0
      pagination_block = pagination_root[0]

      items = pagination_block.xpath('ul/li')

      last_link = items[items.length - 2].xpath('a')

      if last_link.size == 0
        last_link = items[items.length - 3].xpath('a')

        pages = last_link.text.to_i
      else
        href = last_link.attr('href').text

        pattern = path + 'page'

        index1 = href.index(pattern)
        index2 = href.index('/?')

        unless index2
          index2 = href.length-1
        end

        pages = href[index1+pattern.length..index2].to_i
      end
    end

    {
        "page": page,
        "pages": pages,
        "has_previous": page > 1,
        "has_next": page < pages,
    }
  end

  def get_audio_tracks url
    book_id = 0

    document = fetch_document(url: url)

    scripts = document.xpath('//script[@type="text/javascript"]')

    scripts.each do |script|
      script_body = script.text

      index = script_body.index('$(document).audioPlayer')

      if index
        book_id = script_body[28..script_body.index(',')-1].to_i
        break
      end
    end

    if book_id > 0
      new_url = "#{URL}/rest/bid/#{book_id}"

      tracks = to_json(http_request(url: new_url).body)

      tracks.each do |track|
        track[:name] = track['title'] + '.mp3'
        track[:url] = track['mp3'].encode('utf-8')

        track.delete('title')
        track.delete('mp3')
      end
    else
      tracks = []
    end

    tracks
  end

  def search query, page=1
    path = '/search/books/'

    page_path = get_page_path(path, page)

    content = http_request(url: URL + page_path, query: {q: query}).body

    document = to_document(content, encoding='utf-8')

    get_book_items(document, path=path, page=page)
  end

  def generate_authors_list file_name
    data = []

    result = get_authors(page: 1)

    data += result[:items]

    pages = result[:pagination][:pages]

    progressbar = ProgressBar.create(title: 'Authors', total: pages)
    progressbar.increment

    (2..pages).each_with_index do |page, index|
      result = get_authors(page: page)

      data += result[:items]

      progressbar.progress = index
    end

    File.open(file_name, 'w').write(JSON.pretty_generate(data))

    progressbar.finish
  end

  def generate_performers_list file_name
    data = []

    result = get_performers(page: 1)

    data += result[:items]

    pages = result[:pagination][:pages]

    progressbar = ProgressBar.create(title: 'Performers', total: pages)
    progressbar.increment

    (2..pages).each_with_index do |page, index|
      result = get_performers(page: page)

      data += result[:items]

      progressbar.progress = index
    end

    File.open(file_name, 'w').write(JSON.pretty_generate(data))

    progressbar.finish
  end

  def group_items_by_letter items
    groups = {}

    items.each do |item|
      name = item['name']
      path = item['path']

      group_name = name[0..3].upcase

      unless groups.keys.include? group_name
        group = []

        groups[group_name] = group
      end

      groups[group_name] << {'path': path, 'name': name}
    end

    merge_small_groups(groups)
  end

  def merge_small_groups groups
    # merge groups into bigger groups with size ~ 20 records

    classifier = []

    group_size = 0
    classifier << []
    index = 0

    groups.each do |group_name, value|
      group_weight = groups[group_name].length
      group_size += group_weight

      if group_size > 20 or starts_with_different_letter(classifier[index], group_name)
        group_size = 0
        classifier. << []
        index = index + 1
      end

      classifier[index] << group_name
    end

    # flatten records from different group within same classification
    # assign new name in format first_name-last_name, e.g. ABC-AZZ

    new_groups = {}

    classifier.each do |group_names|
      start_group_name = group_names[0]
      end_group_name =  group_names[group_names.length - 1]

      key =
        if start_group_name == end_group_name
          start_group_name
        else
          start_group_name + "-" + end_group_name
        end

      new_groups[key] = []

      group_names.each do |group_name|
        groups[group_name].each do |item|
          new_groups[key] << item
        end
      end
    end

    new_groups
  end

  def starts_with_different_letter list, name
    result = false

    list.each do |n|
      if name[0] != n[0]
          result = true
          break
      end
    end

    result
  end

end