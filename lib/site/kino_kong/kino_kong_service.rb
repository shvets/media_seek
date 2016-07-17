# coding: utf-8

require 'uri'
require 'ruby-progressbar'

require 'common/http_service'

class KinoKongService < HttpService
  URL = 'http://kinokong.net'

  def get_page_path(path, page=1)
    if page == 1
      new_path = path
    else
      new_path = path + "page/" + page.to_s + "/"
    end

    new_path
  end

  def get_all_movies(page=1)
    get_movies("/films/", page=page)
  end

  def get_new_movies(page=1)
    get_movies("/films/novinki", page=page)
  end

  def get_all_series(page=1)
    get_movies("/serial/", page=page)
  end

  def get_animation(page=1)
    get_movies("/multfilm/", page=page)
  end

  def get_anime(page=1)
    get_movies("/anime/", page=page)
  end

  def get_tv_shows(page=1)
    get_movies("/dokumentalnyy/", page=page)
  end

  def get_movies(path, page=1)
    data = []

    page_path = get_page_path(path, page)

    document = fetch_document(url: URL + page_path, headers: get_headers)

    items = document.xpath('//div[@class="owl-item"]/div')

    items.each do |item|
      shadow_node = item.xpath('div[@class="main-sliders-shadow"]')
      title_node = item.xpath('div[@class="main-sliders-title"]')
      season_node = shadow_node.xpath('div/div[@class="main-sliders-season"]')
      bg_node = shadow_node.xpath('div/span[@class="main-sliders-bg"]')

      href_link = bg_node.xpath('a[@class="main-sliders-play"]')
      thumb_link = shadow_node.xpath('div/img')

      href = href_link.xpath('@href').text
      href = href[URL.size..-1]

      thumb = thumb_link.xpath('@src').text

      unless thumb.index(URL)
        thumb = URL + thumb
      end

      name = title_node.text.strip

      if season_node.size > 0
        type = 'serie'
      else
        type = 'movie'
      end

      data << {type: type, path: href, thumb: thumb, name: name}
    end

    pagination = extract_pagination_data(page_path, page=page)

    {"items": data, "pagination": pagination["pagination"]}
  end

  def get_movies_by_rating(page=1)
    get_movies_by_criteria_paginated( "/?do=top&mode=rating", page=page)
  end

  def get_movies_by_views(page=1)
    get_movies_by_criteria_paginated( "/?do=top&mode=views", page=page)
  end

  def get_movies_by_comments(page=1)
    get_movies_by_criteria_paginated( "/?do=top&mode=comments", page=page)
  end

  def get_movies_by_criteria(path)
    data = []

    document = fetch_document(url: URL + path, headers: get_headers)

    items = document.xpath('//div[@id="dle-content"]/div/div/table/tr')

    items.each do |item|
      link = item.xpath('td/a')

      if link
        href = link.xpath('@href').text

        href = href[URL.size..-1]

        name = link.text.strip

        tds = item.xpath('td')
        rating = tds[tds.size-1].text

        if href
          data << {'path': href, 'name': name, 'rating': rating}
        end
      end
    end

    data
  end

  def get_movies_by_criteria_paginated(path, page=1, page_size=25)
    data = get_movies_by_criteria(path=path)

    {
        "items": data[(page-1)*page_size..page*page_size],
        "pagination": build_pagination_data(data, page, page_size)
    }
  end

  def build_pagination_data(data, page, page_size)
    pages = data.size / page_size

    {
      'page': page,
      'pages': pages,
      'has_next': page < pages,
      'has_previous': page > 1
    }
  end

  def search(query, page: 1, page_size: 15)
    page = page.to_i

    search_data = {
        'do': 'search',
        'subaction': 'search',
        'search_start': page,
        'full_search': 1,
        'story': URI.escape(query.encode('cp1251'))
    }

    if page > 1
      puts page.to_i * page_size.to_i + 1
      search_data['result_from'] = page * page_size + 1
    end

    path = "/index.php?do=search"

    response = http_request(url: URL + path, method: :post, data: search_data, headers: get_headers)
    content = response.body

    document = to_document(content)

    data = []

    items = document.xpath('//div[@class="owl-item"]/div')

    items.each do |item|
      shadow_node = item.xpath('div[@class="main-sliders-shadow"]')
      title_node = item.xpath('div[@class="main-sliders-title"]')
      season_node = shadow_node.xpath('div/div[@class="main-sliders-season"]')
      bg_node = shadow_node.xpath('div/span[@class="main-sliders-bg"]')

      href_link = bg_node.xpath('a[@class="main-sliders-play"]')
      thumb_link = shadow_node.xpath('div/img')

      href = href_link.xpath('@href').text
      href = href[URL.size..-1]

      thumb = thumb_link.xpath('@src').text

      if thumb.index(URL) == -1
        thumb = URL + thumb
      end

      name = title_node.text.strip

      if season_node.size > 0
        type = 'serie'
      else
        type = 'movie'
      end

      data << {type: type, path: URL+href, thumb: thumb, name: name}
    end

    pagination = extract_pagination_data(path, page=page)

    {"items": data, "pagination": pagination["pagination"]}
  end

  def extract_pagination_data(path, page)
    document = fetch_document(url: URL + get_page_path(path), headers: get_headers)

    pages = 1

    response = {}

    pagination_root = document.xpath('//div[@class="basenavi"]/div[@class="navigation"]')

    if pagination_root and pagination_root.size > 0
        pagination_node = pagination_root[0]

        links = pagination_node.xpath('a')

        pages = links[links.size-1].text.to_i
    end

    response["pagination"] = {
        "page": page,
        "pages": pages,
        "has_previous": page > 1,
        "has_next": page < pages,
    }

    response
  end

  def get_serie_playlist_url(path)
    url = nil

    document = fetch_document(url: path, headers: get_headers)

    items = document.xpath('//script')

    items.each do |item|
      text = item.text

      if text
        index1 = text.index('pl:')

        if index1
          index2 = text[index1..-1].index('",')

          if index2
            url = text[index1+4..index1+index2-1]
            break
          end
        end
      end

    end

    url
  end

  def get_urls(url)
    urls = nil

    document = fetch_document(url: url, headers: get_headers)

    items = document.xpath('//script')

    items.each do |item|
      text = item.text

      if text
        index1 = text.index('"file":"')
        index2 = text.index('"};')

        if index1 and index2
          urls = text[index1+8..index2-1].split(',')
          break
        end
      end
    end

    list = []

    urls.each do |url|
      index = url.rindex('/')
      name = url[index+1..-1]

      list << {type: 'movie', url: url, name: name}
    end

    list
  end

  def get_serie_info(url)
    playlist_url = get_serie_playlist_url(url)

    content = fetch_content(url: playlist_url, headers: get_headers)

    index = content.index('{"playlist":')

    serie_info = to_json(content[index..-1])['playlist']

    if serie_info and serie_info.size > 0 and not serie_info[0]['playlist']
      serie_info = [{
        comment: "Сезон 1",
        playlist: serie_info
      }]
    end

    serie_info.each do |item|
      item[:playlist].each do |item2|
        files = item2['file'].split(',')

        item2[:file] = []

        files.each do |file|
          if file
            item2[:file] << file
          end
        end

        item2[:comment] = item2['comment']

        item2.delete('file')
        item2.delete('comment')
      end
    end

    serie_info
  end

  def get_tags
    data = []

    document = fetch_document(url: URL + '/podborka.html', headers: get_headers)

    items = document.xpath('//div[@class="podborki-item-block"]')

    items.each do |item|
      link = item.xpath('a')
      img = item.xpath('a/span/img')
      title = item.xpath('a/span[@class="podborki-title"]')

      href = link.xpath('@href').text

      thumb = img.xpath('@src').text

      unless thumb.index(URL)
        thumb = URL + thumb
      end

      name = title.text.strip

      data << {'path': href, 'thumb': thumb, 'name': name}
    end

    data
  end

  def get_grouped_genres
    data = {}

    document = fetch_document(url: URL, headers: get_headers)

    items = document.xpath('//div[@id="header"]/div/div/div/ul/li')

    items.each do |item|
      href_link = item.xpath('a')
      genres_node1 = item.xpath('span/em/a')
      genres_node2 = item.xpath('span/a')

      href = href_link.xpath('@href').text
      href = href[1..href.size-1]

      if href == ''
        href = 'top'
      end

      if genres_node1.size > 0
        genres_node = genres_node1
      else
        genres_node = genres_node2
      end

      if genres_node.size > 0
        data[href] = []

        genres_node.each do |genre|
          path = genre.xpath('@href').text
          name = genre.text.strip

          unless ['/recenzii/', '/news/'].include? path
            data[href] << {'path': path, 'name': name}
          end
        end
      end
    end

    data
  end


  def get_series(path, page=1)
    get_movies(path=path, page=page)
  end

  def get_movie(url)
    headers = {}

    http_request(url, headers=headers).body
  end

  # def get_metadata(url)
  #   data = {}
  #
  #   groups = url.split('.')
  #   text = groups[groups.size - 2]
  #
  #   result = re.search('(\d+)p_(\d+)', text)
  #
  #   if result and result.groups.size == 2
  #     data['width'] = result.group(1)
  #     data['video_resolution'] = result.group(1)
  #     data['height'] = result.group(2)
  #   else
  #     result = re.search('_(\d+)', text)
  #
  #     if result and result.groups.size == 1
  #       data['width'] = result.group(1)
  #       data['video_resolution'] = result.group(1)
  #     end
  #   end
  #
  #   data
  # end
  #
  # def get_urls_metadata(urls)
  #   urls_items = []
  #
  #   urls.each do |url|
  #     url_item = {
  #         "url": url,
  #         "config": {
  #             "container": 'MP4',
  #             "audio_codec": 'AAC',
  #             "video_codec": 'H264',
  #         }
  #     }
  #
  #     groups = url.split('.')
  #     text = groups[groups.size-2]
  #
  #     re = /(\d+)p_(\d+)/
  #     result = re.gsub(text)
  #
  #     if result and result.groups.size == 2
  #       url_item['config']['width'] = result.group(1)
  #
  #       url_item['config']['video_resolution'] = result.group(1)
  #       url_item['config']['height'] = result.group(2)
  #     else
  #       result = re.search('_(\d+)', text)
  #
  #       if result and result.groups.size == 1
  #         url_item['config']['width'] = result.group(1)
  #         url_item['config']['video_resolution'] = result.group(1)
  #       end
  #     end
  #
  #     urls_items << url_item
  #   end
  #
  #   urls_items
  # end

  def get_episode_url(url, season, episode)
    if season
      "#{url}?season=#{season}&episode=#{episode}"
    end

    url
  end

  def get_headers()
    {
      'User-Agent': 'Plex-User-Agent'
    }
  end

end



