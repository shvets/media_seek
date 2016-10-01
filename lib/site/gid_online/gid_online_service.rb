# coding: utf-8

require 'uri'
require 'json'
require 'base64'
require 'ruby-progressbar'
require 'script_executor'

require 'common/http_service'

class GidOnlineService < HttpService
  URL = 'http://gidonline.club'
  SESSION_URL1 = 'http://pandastream.cc/sessions/create_new'
  SESSION_URL2 = 'http://pandastream.cc/sessions/new'

  def session_url
    SESSION_URL1
  end

  def get_page_path(path, page=1)
    if page == 1
      new_path = path
    else
      new_path = path + "page/" + page.to_s + "/"
    end

    new_path
  end

  def get_genres(document, type=nil)
    list = []

    links = document.xpath('//div[@id="catline"]//li/a')

    links.each do |link|
      path = link.xpath('@href')[0].text
      name = link.xpath('text()')[0].text

      list << {"path": path, "name": name[0] + name[1..-1].downcase}
    end

    family_group = [
        list[14],
        list[15],
        list[12],
        list[8],
        list[10],
        list[5],
        list[13]
    ]

    crime_group = [
        list[4],
        list[9],
        list[2],
        list[0]
    ]

    fiction_group = [
        list[20],
        list[19],
        list[17],
        list[18]
    ]

    education_group = [
        list[1],
        list[7],
        list[3],
        list[6],
        list[11],
        list[16]
    ]

    case type
      when 'Family'
        family_group
      when 'Crime'
        crime_group
      when 'Fiction'
        fiction_group
      when 'Education'
        education_group
      else
        family_group + crime_group + fiction_group + education_group
    end
  end

  def get_top_links(document)
    list = []

    links = document.xpath('//div[@id="topls"]/a[@class="toplink"]')

    links.each do |link|
      path = link.xpath('@href')[0].text
      name = link.xpath('text()')[0].text
      thumb = URL + (link.xpath('img')[0].xpath("@src"))[0]

      list << {"path": path, "name": name, "thumb": thumb}
    end

    list
  end

  def get_actors(document, letter=nil)
    all_list = fix_name(get_category('actors-dropdown', document))

    all_list.sort_by! {|item| item[:name]}

    if letter
      list = []

      all_list.each do |item|
        if item[:name][0] == letter
          list << item
        end
      end
    else
      list = all_list
    end

    fix_path(list)
  end


  def get_directors(document, letter=nil)
    all_list = fix_name(get_category('director-dropdown', document))

    all_list.sort_by! {|item| item[:name]}

    if letter
      list = []

      all_list.each do |item|
        if item[:name][0] == letter
          list << item
        end
      end
    else
      list = all_list
    end

    fix_path(list)
  end

  def get_countries(document)
    fix_path(get_category('country-dropdown', document))
  end

  def get_years(document)
    fix_path(get_category('year-dropdown', document))
  end

  def get_seasons(path)
    get_category('season', get_movie_document(URL + path))
  end

  def get_episodes(path)
    get_category('episode', get_movie_document(URL + path))
  end

  def get_category(id, document)
    list = []

    links = document.xpath('//select[@id="' + id + '"]/option')

    links.each do |link|
      path = link.xpath('@value')[0].text
      name = link.text

      if name
        list << {"path": path, "name": name}
      end
    end

    list
  end

  def retrieve_urls(url, season=nil, episode=nil)
    unless url.index(URL) or url.index("http://")
      url = URL + url
    end

    document = get_movie_document(url, season=season, episode=episode)
    content = document.to_html

    data = get_session_data(content)

    content_data = get_content_data(content)

    headers = {
      'X-Requested-With': 'XMLHttpRequest',
      'Encoding-Pool': content_data
    }

    get_urls(headers, data)
  end

  def get_urls(headers, data)
    urls = []

    begin
      response = http_request(method: :post, url: session_url, headers: headers, data: data)

      data = JSON.parse(response.body)

      manifest_url = data['manifest_m3u8']

      response2 = http_request(url: manifest_url)

      lines = StringIO.new(response2.body).readlines

      lines.each_with_index do |line, index|
        if line.start_with?('#EXTM3U')
          next
        elsif line.strip.size > 0 and not line.start_with?('#EXT-X-STREAM-INF')
          data = lines[index-1].match /#EXT-X-STREAM-INF:RESOLUTION=(\d+)x(\d+),BANDWIDTH=(\d+)/

          urls << {type: 'movie', url: line.strip, width: data[1].to_i, height: data[2].to_i, bandwidth: data[3].to_i}
        end
      end
    rescue
      ;
    end

    urls
  end

  def get_movie_document(url, season=nil, episode=nil)
    gateway_url = get_gateway_url(fetch_document(url: url))

    if season
      movie_url = "#{gateway_url}?season=#{season}&episode=#{episode}"
    else
      movie_url = gateway_url

      if movie_url.index('//www.youtube.com')
        movie_url = movie_url.gsub('//', 'http://')
      end
    end

    fetch_document(url: movie_url, headers: get_headers(gateway_url))
  end

  def get_gateway_url(document)
    gateway_url = nil

    frame_block = document.xpath('//div[@class="tray"]')[0]

    urls = frame_block.xpath('iframe[@class="ifram"]/@src').text

    if urls.strip.length > 0
      gateway_url = urls
    else
      url = URL + '/trailer.php'

      data = {
        'id_post': document.xpath('//head/meta[@id="meta"]').xpath('@content')
      }
      response = http_request(url: url, method: :post, data: data)

      content = response.body

      document = to_document(content)

      urls = document.xpath('//iframe[@class="ifram"]/@src').text

      if urls.strip.length > 0
        gateway_url = urls
      end
    end

    gateway_url
  end

  def get_session_data(content)
    path = URI(session_url).path
    expr1 = "$.post('" + path + "'"
    expr2 = "}).success("

    index1 = content.index(expr1)

    if index1
      index2 = content[index1..-1].index(expr2)

      session_data = content[index1+expr1.size+1..index1+index2].strip

      if session_data
        session_data = session_data.gsub('condition_detected ? 1 : ', '')

        new_session_data = replace_keys(session_data,
                                        ['partner', 'd_id', 'video_token', 'content_type', 'access_key', 'cd'])

        JSON.parse(new_session_data)
      end
    end
  end

  def replace_keys(s, keys)
    s = s.gsub('\'', '"')

    keys.each do |key|
      s = s.gsub(key + ':', '"' + key + '":')
    end

    s
  end

  def get_content_data(content)
    data = content.match(/setRequestHeader\|\|([^|]+)/m)

    if data
      Base64.encode64(data[1]).strip
    end
  end

  def get_serial_info(document)
    ret = {}

    ret['seasons'] = {}
    ret['episodes'] = {}

    document.xpath('//select[@id="season"]/option').each do |item|
      value = item.xpath('@value').text.to_i

      ret['seasons'][value] = item.text

      if item.xpath('@selected')
        ret['current_season'] = value.to_i
      end
    end

    document.xpath('//select[@id="episode"]/option').each do |item|
      value = item.xpath('@value').text.to_i

      ret['episodes'][value] = item.text

      if item.xpath('@selected')
        ret['current_episode'] = value.to_i
      end
    end

    ret
  end

  def get_media_data(document)
    data = {}

    block = document.xpath('//div[@id="face"]')[0]

    thumb = block.xpath('div/img[@class="t-img"]')[0].xpath("@src").text

    data['thumb'] = URL + thumb

    items1 = block.xpath('div/div[@class="t-row"]/div[@class="r-1"]//div[@class="rl-2"]')
    items2 = block.xpath('div/div[@class="t-row"]/div[@class="r-2"]//div[@class="rl-2"]')

    data['title'] = items1[0].text
    data['countries'] = items1[1].text.split(',')
    data['duration'] = convert_duration(items1[2].text)
    data['year'] = items2[0].text.to_i
    data['tags'] = items2[1].text.split(',')
    data['genres'] = items2[1].text.split(',')

    description_block = document.xpath('//div[@class="description"]')[0]

    data['summary'] = description_block.xpath('div[@class="infotext"]')[0].text

    data['rating'] = document.xpath('//div[@class="nvz"]/meta')[1].xpath('@content').text.to_f

    data
  end

  def search(query, page: 1)
    url = get_page_path(URL, page) + "?s=" + query

    response = http_request(url: url)

    if [Net::HTTPMovedPermanently, Net::HTTPFound].include? response.class
      location = response['location']

      if URI(location).scheme
        new_uri = URI(location)
      else
        new_uri = URI(url)
        new_uri.path = location
      end

      url = new_uri.to_s

      if is_serial(url)
        document = get_movie_document(url)
        serial_info = get_serial_info(document)

        puts serial_info

        serial_info['seasons'].each do |season, season_name|
          name = season_name.gsub(' ', '_')

          FileUtils.mkdir_p(name)

          puts name

          executor = ScriptExecutor.new

          document2 = get_movie_document(url, season, 1)
          serial_info2 = get_serial_info(document2)

          serial_info2['episodes'].each do |episode, episode_name|
            puts episode_name

            name2 = name + '/' + episode_name.gsub(' ', '_')

            #FileUtils.mkdir_p(name)

            urls = retrieve_urls(url, season=season, episode=episode)

            url = urls[0][:url]

            puts url

            file_name = name2 + '.mp4'

            unless File.exist?(file_name)
              executor.execute "ffmpeg -i " + url + ' ' + '-bsf:a aac_adtstoasc -vcodec copy -c copy -crf 50 ' + file_name
            end

            # ffmpeg -i http://p0.edge02.moonwalk.cc/sec/1469944053/3935323379d2a61bc18b19ac5234078c9fea77a2c8e9cd21/ivs/a9/14/c3a3da9cebf1.mp4/hls/tracks-3,4/index.m3u8 -bsf:a aac_adtstoasc -vcodec copy -c copy -crf 50 file.mp4
            #break
          end

        end
        #
        # for season in sorted(serial_info['seasons'].keys()):
      else
        document = fetch_document(url: url)

        media_data = get_media_data(document)

        {'items': [
            {
                type: 'movie',
                path: new_uri.to_s,
                name: media_data['title'],
                thumb: media_data['thumb']
            }
        ]}
      end
    else
      content = response.body
      document = to_document(content)

      movies = get_movies(document, url)

      if movies[:items].size > 0
        movies
      else
        document = fetch_document(url: response.url)

        media_data = get_media_data(document)

        {'items': [
            {
                type: 'movie',
                path: url,
                name: media_data['title'],
                thumb: media_data['thumb']
            }
        ]}
      end
    end
  end

  def search_actors(document, query)
    search_in_list(get_actors(document), query)
  end

  def search_directors(document, query)
    search_in_list(get_directors(document), query)
  end

  def search_countries(document, query)
    search_in_list(get_countries(document), query)
  end

  def search_years(document, query)
    search_in_list(get_years(document), query)
  end

  def search_in_list(list, query)
    new_list = []

    list.each do |item|
      if item[:name].downcase.index(query.downcase)
        new_list << item
      end
    end

    new_list
  end

  def get_movies(document, path=nil)
    result = {items: []}

    links = document.xpath('//div[@id="main"]/div[@id="posts"]/a[@class="mainlink"]')

    links.each do |link|
      href = link.xpath('@href')[0].text
      name = link.xpath('span')[0].text
      thumb = URL + (link.xpath('img')[0].xpath("@src"))[0]

      result[:items] << { type: 'movie', path: href, name: name, thumb: thumb }

      if result[:items].size > 0
        result["pagination"] = extract_pagination_data(document, path)
      end
    end

    result
  end

  def extract_pagination_data(document, path)
    pagination_root = document.xpath('//div[@id="page_navi"]/div[@class="wp-pagenavi"]')

    if pagination_root and pagination_root.size > 0
      pagination_block = pagination_root[0]

      page = pagination_block.xpath('span[@class="current"]')[0].text.to_i

      last_block = pagination_block.xpath('a[@class="last"]')

      if last_block.size > 0
        pages_link = last_block[0].xpath('@href').text

        pages = find_pages(path, pages_link)
      else
        page_block = pagination_block.xpath('a[@class="page larger"]')
        pages_len = page_block.size

        if pages_len == 0
          pages = page
        else
          pages_link = page_block[pages_len - 1].xpath('@href').text

          pages = find_pages(path, pages_link)
        end
      end
    else
      page = 1
      pages = 1
    end

    {
      page: page,
      pages: pages,
      has_previous: page > 1,
      has_next: page < pages,
    }
  end

  def find_pages(path, link)
    search_mode = (path and path.index('?s='))

    if path
      if search_mode
        pattern = URL + '/page/'
      else
        pattern = URL + path + 'page/'
      end
    else
      pattern = URL + '/page/'
    end

    re_pattern = '(' + pattern + ')(\d*)/'

    data = link.match /#{re_pattern}/

    data[2].to_i
  end

  def fix_path(list)
    list.each do |item|
      item[:path] = item[:path][URL.size..-1]
    end

    list
  end

  def is_serial(path)
    document = get_movie_document(path)

    content = document.to_s

    data = get_session_data(content)

    data and data['content_type'] == 'serial' or has_seasons(path)
  end

  def has_seasons(url)
    path = URI(url).path

    get_seasons(path).size > 0
  end

  def fix_name(list)
    list.each do |item|
      name = item[:name]

      names = name.split(' ')

      if names.size > 1
        item[:name] = names[names.size-1..-1].join(" ") + ', ' + names[0..names.size-1][0]
      end
    end

    list
  end

  def convert_duration(s)
    tokens = s.split(' ')

    result = []

    tokens.each do |token|
      data = token.match /(\d+)/

      if data
        result << data[0]
      end
    end

    if result.size == 2
      hours = result[0].to_i
      minutes = result[1].to_i
    else
      hours = 0
      minutes = result[0].to_i
    end

    hours * 60 * 60 + minutes * 60
  end

  def get_headers(referer)
    {
      'User-Agent': 'Plex-User-Agent',
      "Referer": referer
    }
  end
end
