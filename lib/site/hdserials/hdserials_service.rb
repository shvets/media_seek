# coding: utf-8

require 'uri'
require 'json'
require 'base64'

require 'common/http_service'

class HDSerialsService < HttpService
  URL = 'http://www.hdserials.tv'
  SESSION_URL = 'http://pandastream.cc/sessions/new'

  def get_page_path(path, page=1)
    if page == 1
      new_path = path
    else
      new_path = path[0..path.size - 6] + '/Page-' + page.to_s + '.html'
    end

    new_path
  end

  def get_categories
    list = []

    document = fetch_document(url: URL)

    links = document.xpath('//div[@id="gkMenu"]/div/ul/li/a')

    links.each do |link|
      path = link.xpath('@href')[0].text

      if path != '/' and path != URL + '/'
        title = link.text

        list << {path: path, title: title}
      end
    end

    list
  end

  def get_new_series
    list = []

    document = fetch_document(url: URL)

    items = document.xpath('//div[@id="gkHeaderheader1"]//div[@class="custom"]/div')

    items.each do |item|
      link = item.xpath('a')

      path = link.xpath('@href')[0].text
      title = link.text
      text = item.xpath('span')[0].text + ' ' + title

      list << {path: path, title: title, text: text}
    end

    list
  end

  def get_popular(page=1, per_page=20)
    list = []

    document = fetch_document(url: URL + '/popular.html')

    items = document.xpath('//div[contains(@class, "nspArts")]//div[contains(@class, "nspArt")]/div')

    items.each_with_index do |item, index|
      if index >= (page - 1) * per_page and index < page * per_page
        link = item.xpath('a')

        path = URL + link.xpath('@href')[0] .text

        if path
          title = item.xpath('h4').text

          thumb = link.xpath('img').xpath('@src').text

          list << {'path': path, 'title': title, 'thumb': thumb}
        end
      end
    end

    pagination = extract_pagination_data_from_array(items, page, per_page)

    {items: list, pagination: pagination[:pagination]}
  end

  def extract_pagination_data_from_array(items, page, per_page)
    pages = items.size / per_page

    if items.size % per_page > 0
      pages = pages + 1
    end

    response = {}

    response[:pagination] = {
        page: page,
        pages: pages,
        has_previous: page > 1,
        has_next: page < pages,
    }

    response
  end

  def get_subcategories(path, page=1, per_page=20)
    # page = int(page)
    # per_page = int(per_page)

    list = []

    document = fetch_document(url: URL + path)

    items = document.xpath('//div[@class="itemListSubCategories"]//div[contains(@class, "subCategory")]/h2/a')

    items.each_with_index do |item, index|
      if index >= (page - 1) * per_page and index < page * per_page
        href = item.xpath('@href')[0].text

        title = item.text

        list << {'path': href, 'title': title}
      end
    end

    pagination = extract_pagination_data_from_array(items, page, per_page)

    {data: list, pagination: pagination[:pagination]}
  end

  def get_category_items(path, page=1)
    list = []

    page_path = get_page_path(path, page)

    document = fetch_document(url: URL + page_path)

    links = document.xpath('//div[@class="itemList"]//div[@class="catItemBody"]//span[@class="catItemImage"]/a')

    links.each do |link|
      href = URL + link.xpath('@href')[0].text
      title = link.xpath('@title').text
      thumb = link.xpath('img').xpath('@src').text

      list << {'path': href, 'title': title, thumb: thumb}
    end

    pagination = extract_pagination_data(page_path)

    {items: list, pagination: pagination["pagination"]}
  end

  def extract_pagination_data(path)
    document = fetch_document(url: URL + path)

    page = 1
    pages = 1

    response = {}

    pagination_root = document.xpath('//div[@class="k2Pagination"]')

    if pagination_root
      pagination_block = pagination_root[0]

      counter_block = pagination_block.xpath('//div/p[@class="counter"]/span')

      if counter_block
        counter = counter_block[0].text

        phrase = counter.split(' ')

        page = phrase[1].to_i
        pages = phrase[3].to_i
      end
    end

    response["pagination"] = {
        page: page,
        pages: pages,
        has_previous: page > 1,
        has_next: page < pages,
    }

    response
  end

  def get_media_data(document)
    data = {}

    block = document.xpath('//div[@id="k2Container"]')[0]

    thumb = block.xpath('//div/span[@class="itemImage"]/a/img')[0].xpath("@src").text

    data['thumb'] = URL + thumb

    title_block = block.xpath('//h2[@class="itemTitle"]')[0].text.split('/')

    titles = []

    title_block.each do |l|
      titles << l.strip
    end

    if titles.size > 1
      data['title'] = titles[0] + ' / ' + titles[1]
    else
      data['title'] = titles[0]
    end

    rating_block = block.xpath('//div[@class="itemRatingBlock"]//li[@class="itemCurrentRating"]')[0].xpath('@style')
    data['rating'] = rating_block.text.match(/width\s?:\s?([\d\.]+)/)[1].to_f / 10

    description_block = block.xpath('//div[@class="itemFullText"]')[0]

    description = {}

    description_block.xpath('p')[0].each do |elem|
      key = elem.text

      if key.strip.size > 0
        if key == 'Продолжительность'
          value = elem.tail.strip[2..-1]
        elsif elem.tail
          value = elem.tail.replace(':', '')
        else
          value = ''
        end

        description[key] = value
      end
    end

    if description.size > 0
      unless description['В ролях']
        description[u'В ролях'] = ''
      end
    else
      text = description_block.text

      text, roles = text.split('В ролях:')
      text, director = text.split('Режиссер:')
      text, translation = text.split('Перевод:')
      text, duration = text.split('Продолжительность:')
      text, genre = text.split('Жанр:')
      text, country = text.split('Страна:')
      text, year = text.split('Год выпуска:')
      _, text = text.split('Описание:')

      description['Описание'] = text
      description['Страна'] = country
      description['Жанр'] = genre
      description['Перевод'] = translation
      description['Режиссер'] = director
      description['В ролях'] = roles
      description['Продолжительность'] = duration
      description['Год выпуска'] = year
    end

    summary = description['Описание'] + '\n' + \
            'Страна'  + ': ' + description['Страна'] + '\n' + \
            'Жанр' + ': ' + description['Жанр'] + '\n' + \
            'Перевод' + ': ' + description['Перевод'] + '\n' + \
            'Режиссер' + ': ' + description['Режиссер'] + '\n' + \
            'В ролях' + ': ' + description['В ролях'] + '\n'

    data['duration'] = convert_duration(description['Продолжительность'])

    begin
      data['year'] = description['Год выпуска'].to_i
    rescue
      data['year'] = description['Год выпуска'][0..4].to_i
    end

    data['tags'] = description['Жанр'].gsub(',', ', ').split(',')
    data['genres'] = description['Жанр'].gsub(',', ', ').split(',')
    data['summary'] = summary
    data['countries'] = description['Страна'].split(',')
    data['directors'] = description['Режиссер'].split(' ')

    data
  end

  def search(query)
    params = {
        'option': 'com_k2',
        'view': 'itemlist',
        'task': 'search',
        'searchword': query,
        'categories': '',
        'format': 'json',
        'tpl': 'search',
    }

    url = build_url(URL + "/index.php", **params)

    content = fetch_content(url: url)

    result = {items: []}

    data = JSON.parse(content)

    if data['items']
      data['items'].each do |item|
        title = item['category']['name'] + ' / ' + item['title']
        key = URL + item['link']
        rating_key = item['link']
        thumb = URL + item['image']
        summary = to_document(item['introtext']).text
        path = URL + item['link']

        movie = {
            "key": key,
            "rating_key": rating_key,
            "name": title,
            "thumb": thumb,
            "summary": summary,
            "path": path
        }

        result[:items] << movie
      end
    end

    result
  end

  def convert_duration(s)
    s = s.gsub('~', '').strip

    if s.index('мин')
      s = "00:" + s.gsub('мин', '').gsub(' ', '') + ":00"
    end

    tokens = s.split(' ')

    result = []

    tokens.each do |token|
      data = token.match /(\d+)/

      if data
        result << data[0]
      end
    end

    if result.size == 3
      hours = result[0].to_i
      minutes = result[1].to_i
      seconds = result[2].to_i
    elsif result.size == 2
      hours = result[0].to_i
      minutes = result[1].to_i
      seconds = 0
    else
      hours = 0
      minutes = result[0].to_i
      seconds = 0
    end

    hours * 60 * 60 + minutes * 60 + seconds
  end
end
