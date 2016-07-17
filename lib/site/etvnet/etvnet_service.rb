# coding: utf-8

require_relative 'api_service'

class EtvnetService < ApiService
  PER_PAGE = 15

  API_URL = 'https://secure.etvnet.com/api/v3.0/'
  USER_AGENT = 'Plex User Agent'

  AUTH_URL = 'https://accounts.etvnet.com/auth/oauth/'
  CLIENT_ID = "a332b9d61df7254dffdc81a260373f25592c94c9"
  CLIENT_SECRET = '744a52aff20ec13f53bcfd705fc4b79195265497'

  SCOPE = [
    'com.etvnet.media.browse',
    'com.etvnet.media.watch',
    'com.etvnet.media.bookmarks',
    'com.etvnet.media.history',
    'com.etvnet.media.live',
    'com.etvnet.media.fivestar',
    'com.etvnet.media.comments',
    'com.etvnet.persons',
    'com.etvnet.notifications'
  ].join(' ')

  GRANT_TYPE = 'http://oauth.net/grant_type/device/1.0'

  TIME_SHIFT = {
      '0': 0,  # Moscow
      '1': 2,  # Berlin
      '2': 3,  # London
      '3': 8,  # New York
      '4': 9,  # Chicago
      '5': 10, # Denver
      '6': 11  # Los Angeles
  }

  TOPICS = ["etvslider/main", "newmedias", "best", "top", "newest", "now_watched", "recommend"]

  def initialize(config)
    @last_url_requested = nil

    super(config, API_URL, USER_AGENT, AUTH_URL, CLIENT_ID, CLIENT_SECRET, GRANT_TYPE, SCOPE)
  end

  def on_authorization_success(user_code, device_code, activation_url)
    puts("Register activation code on web site (" + activation_url + "): " + user_code)

    response = nil

    done = false

    until done
      response = create_token(device_code=device_code)

      if response
        done = response.keys.include?('access_token')
      end

      unless done
        sleep(5)
      end
    end

    @config.save(response)

    response
  end

  def get_channels(today: false)
    path = 'video/channels.json'

    to_json(full_request(build_url(path, today: today)))
  end

  def get_archive(genre: nil, channel_id: nil, per_page: PER_PAGE, page: 1)
    if channel_id and genre
      path = "video/media/channel/#{channel_id}/archive/#{genre}.json"
    elsif genre
      path = "video/media/archive/#{genre}.json"
    elsif channel_id
      path = "video/media/channel/#{channel_id}/archive.json"
    else
      path = "video/media/archive.json"
    end

    params = {}
    params[:per_page] = per_page
    params[:page] = page

    url = build_url(path, **params)

    @last_url_requested = url

    to_json(full_request(url))
  end

  def get_genres(parent_id=nil, today=false, channel_id=nil, format=nil)
    path = 'video/genres.json'
    today = today ? 'yes' : nil

    params = {}
    params[:parent] = parent_id
    params[:today] = today
    params[:channel] = channel_id
    params[:format] = format

    url = build_url(path, **params)

    result = to_json(full_request(url))

    # regroup genres

    data = result['data']

    genres = []

    genres << data[0]
    genres << data[1]
    genres << data[5]
    genres << data[9]
    genres << data[7]
    genres << data[2]
    genres << data[3]
    genres << data[4]
    genres << data[6]
    genres << data[8]
    genres << data[10]
    genres << data[11]
    genres << data[12]
    #genres << data[13]
    genres << data[14]
    #genres << data[15]

    result['data'] = genres

    result
  end

  def get_genre(genres, name)
    genre = nil

    genres['data'].each do |item|
      if item['name'] == name
        genre = item['id']

        break
      end
    end

    genre
  end

  def get_blockbusters(per_page=PER_PAGE, page=1)
    genres = get_genres

    genre = get_genre(genres, "Блокбастеры")

    get_archive(genre: genre, per_page: per_page, page: page)
  end

  def search(query:, per_page: PER_PAGE, page: 1, dir: nil)
    unless dir
      dir = 'desc'
    end

    path = 'video/media/search.json'

    params = {}
    params[:q] = query
    params[:per_page] = per_page
    params[:page] = page
    params[:dir] = dir

    to_json(full_request(build_url(path, **params)))
  end

  def get_new_arrivals(genre=nil, channel_id=nil, per_page=PER_PAGE, page=1)
    if channel_id and genre
      path = "video/media/channel/#{channel_id}/new_arrivals/#{genre}.json"
    elsif genre
      path = "video/media/new_arrivals/#{genre}.json"
    elsif channel_id
      path = "video/media/channel/#{channel_id}/new_arrivals.json"
    else
      path = 'video/media/new_arrivals.json'
    end

    params = {}
    params[:per_page] = per_page
    params[:page] = page

    url = build_url(path, **params)

    to_json(full_request(url))
  end

  def get_url(media_id, format: 'mp4', protocol: 'hls', bitrate: nil, other_server: nil, offset: nil,
              live: false, channel_id: nil, preview: false)
    if format == 'zixi'
      format = 'mp4'
    end


    if live
      # if format == 'mp4':
      #     protocol = 'hls'

      path = "video/live/watch/#{channel_id}.json"

      params = {"offset": offset, "format": format, "bitrate": bitrate, "other_server": other_server}
    else
      if format == 'wmv'
        protocol = None
      end

      if format == 'mp4' and not protocol
        protocol = 'rtmp'
      end

      if preview
        link_type = 'preview'
      else
        link_type = 'watch'
      end

      path = "video/media/#{media_id}/#{link_type}.json"

      params = {"format": format, "protocol": protocol, "bitrate": bitrate, "other_server": other_server}
    end

    path = build_url(path, **params)

    result = to_json(full_request(path))

    if result
      {url: result['data']['url'], protocol: protocol, format: format, bitrate: bitrate}
    else
      {url: nil, protocol: nil, format: nil, bitrate: nil}
    end
  end

  def bitrates(data, accepted_format=nil, quality_level=nil)
    bitrates = {}

    data.each do |pair|
      format = pair['format']
      bitrate = pair['bitrate']

      if not accepted_format or accepted_format == format
        unless bitrates.keys.include? format
          bitrates[format] = []
        end

        bitrates[format] << bitrate
      end
    end

    bitrates.keys.each do |key|
      #bitrates[key] = self.filtered(sorted(bitrates[key], reverse=True), quality_level)
      bitrates[key] = filtered(bitrates[key], quality_level)
    end

    bitrates
  end

  def filtered(bitrates, quality_level)
    if quality_level == nil
      return bitrates
    else
      # Best, High, Medium, Low, Undefined
      filter_map = {
          '1': [0, 0, 0, 0],
          '2': [1, 0, 0, 0],
          '3': [2, 1, 0, 0],
          '4': [3, 2, 1, 0]
      }
    end

    index = filter_map[bitrates.size][quality_level-1]

    [bitrates[index]]
  end

  def get_children(media_id, per_page=PER_PAGE, page=1, dir=nil)
    path = "video/media/#{media_id}/children.json"

    params = {}
    params[:per_page] = per_page
    params[:page] = page
    params[:dir] = dir

    url = build_url(path, **params)

    @last_url_requested = url

    to_json(full_request(url))
  end

  def get_bookmarks(folder=nil, per_page=PER_PAGE, page=nil)
    if folder
      params = {"per_page": per_page, "page": page}

      path = 'video/bookmarks/folders/%s/items.json' % folder
    else
      params = {"per_page": per_page, "page": page}

      path = 'video/bookmarks/items.json'
    end

    to_json(full_request(build_url(path, **params)))
  end

  def get_folders(per_page=PER_PAGE)
    to_json(full_request('video/bookmarks/folders.json'))
  end

  def get_bookmark(id)
    to_json(full_request(build_url("video/bookmarks/items/#{id}.json"), method: :get))
  end

  def get_topic_items(id='best', per_page=PER_PAGE, page=nil)
    params = {"per_page": per_page, "page": page}

    url = build_url("video/media/#{id}.json", **params)

    to_json(full_request(url))
  end

  def bitrate_to_resolution(bitrate)
    # table = {
    #     '1080': [3000, 6000],
    #     '720': [1500, 4000],
    #     '480': [500, 2000],
    #     '360': [400, 1000],
    #     '240': [300, 700]
    # }
    # table = {
    #     '1080': [2000, 3000],
    #     '720': [1000, 1800],
    #     '480': [500, 900],
    #     '360': [350, 450],
    #     '240': [000, 300]
    # }
    table = {
        '1080': [1500, 3000],
        '720': [500, 1499],
        '480': [350, 499],
        '360': [200, 349],
        '240': [000, 199]
    }

    video_resolutions = []

    table.each do |key, values|
      if (values[0]..values[1]).include? bitrate
        video_resolutions << key
      end

      video_resolutions
    end
  end

  def get_live_channels(favorite_only=nil, offset=nil, category=0)
    format = 'mp4'

    params = {"format": format, "allowed_only": 1, "favorite_only": favorite_only, "offset": offset}

    if category > 0
      to_json(full_request(build_url("video/live/category/#{category}.json?", **params)))
    else
      to_json(full_request(build_url("video/live/channels.json", **params)))
    end
  end

  def get_live_schedule(live_channel_id, date=Time.now)
    params = {date: date.to_i}

    url = build_url("video/live/schedule/#{live_channel_id}.json" , **params)

    to_json(full_request(url))
  end

  def get_live_categories
    url = build_url("video/live/category.json")

    result = to_json(self.full_request(url))

    # regroup categories

    data = result['data']

    categories = []

    categories << data[8]
    categories << data[6]
    categories << data[3]
    categories << data[2]
    categories << data[1]
    categories << data[5]
    categories << data[7]
    categories << data[0]
    categories << data[4]

    result['data'] = categories

    result
  end
end

