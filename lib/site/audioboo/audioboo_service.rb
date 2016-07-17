# coding: utf-8

require 'common/http_service'
require 'common/downloader'

class AudiobooService < HttpService
  URL = 'http://audioboo.ru'
  ARCHIVE_URL = "https://archive.org"

  def get_letters
    data = []

    document = fetch_document(url: URL)

    items = document.xpath('//div[@class="content"]/div/div/a[@class="alfavit"]')

    items.each do |item|
      href = item.xpath('@href').first.text
      name = item.text.upcase

      data << {'path': href, 'name': name}

      data << name
    end

    data
  end

  def get_authors_by_letter path
    data = []

    document = fetch_document(url: URL + path)

    items = document.xpath('//div[@class="full-news-content"]/div/a')

    items.each do |item|
      href = item.xpath('@href').first.text
      name = item.text.upcase

      data << {'path': href, 'name': name}
    end

    group_items_by_letter data
  end

  def get_author_books(url)
    data = []

    document = fetch_document(url: url)

    items = document.xpath('//div[@class="biography-main"]')

    items.each do |item|
      name = item.xpath('div[@class="biography-title"]/h2/a').text
      href = item.xpath('div/div[@class="biography-image"]/a').xpath("@href").text
      thumb = item.xpath('div/div[@class="biography-image"]/a/img').xpath("@src").text
      content = item.xpath('div[@class="biography-content"]/div').children.first.content.strip
      rating_node = item.xpath('div[@class="biography-content"]/div/div[@class="rating"]/ul/li')

      if rating_node
        rating = rating_node.text
      else
        rating = ''
      end

      data << {'path': href, 'name': name, 'thumb': thumb, 'content': content, 'rating': rating}
    end

    data
  end

  def group_items_by_letter items
    groups = {}

    items.each do |item|
      name = item[:name]
      path = item[:path]

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

  def get_playlist_urls(url)
    data = []

    document = fetch_document(url: url)

    items = document.xpath('//object')

    items.each do |item|
      data << item.xpath("@data").first.text
    end

    data
  end

  def get_audio_tracks(url)
    data = []

    playlist_urls = get_playlist_urls(url)

    document = fetch_document(url: playlist_urls[0])

    scripts = document.xpath('//script')

    scripts.each do |script|
      text = script.text

      index1 = text.index("Play('jw6',")
      index2 = text.index('{"start":0,')

      if index1 and index2
        content = text[index1+10..index2 - 1].strip
        content = content[2..content.size - 2].strip

        data << JSON.parse(content)
      end
    end

    tracks = data[0]

    list = []

    tracks.each do |track|
      url = ARCHIVE_URL + track["sources"][0]["file"]

      index = url.rindex('/')

      name = url[index+1..-1]

      list << {url: url, name: name}
    end

    list
  end

  def search(query)
    url = URL + "/engine/ajax/search.php"

    headers = {'X-Requested-With': 'XMLHttpRequest'}

    response = http_request(url: url, headers: headers, data: {'query': query}, method: :post)

    content_type = response['content-type']
    index = content_type.index("charset=")
    encoding = content_type[index+"charset=".size..-1]

    content = response.body.force_encoding(encoding)

    document = Nokogiri::HTML.fragment(content.encode('utf-8'))

    get_book_items(document)
  end

  def get_book_items document
    data = []

    items = document.xpath('a')

    items.each do |item|
      href = item.xpath('@href').first.text

      name = item.children[1].text

      index = name.index('Год выпуска:'.force_encoding("utf-8"))

      if index
        name = name[0..index-1].strip
      end

      data << {'type': 'book', 'path': href, 'name': name}
    end

    data
  end

  # def convert_track_duration(s)
  #   tokens = s.split(':')
  #
  #   result = []
  #
  #   tokens.each do |token|
  #     data = token.gsub('(\d+)')
  #
  #     if data
  #       result << data.group(0)
  #     end
  #   end
  #
  #   hours = 0
  #   minutes = 0
  #
  #   if result.size > 2
  #     hours = int(result[0])
  #
  #     minutes = result[1].to_i
  #     seconds = result[2].to_i
  #   elif result.size > 1
  #     minutes = int(result[0])
  #     seconds = int(result[1])
  #   else
  #     seconds = int(result[0])
  #   end
  #
  #   (hours * 60 * 60 + minutes * 60 + seconds) * 1000
  # end

end
