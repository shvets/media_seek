require 'ap'
require 'site/etvnet/etvnet_service'
require 'site/etvnet/config'

RSpec.describe EtvnetService do
  let(:subject) {
    config = Config.new("etvnet.config")
    EtvnetService.new(config)
  }

  it 'gets activation codes' do
    result = subject.get_activation_codes

    activation_url = result[:activation_url]
    user_code = result['user_code']
    device_code = result['device_code']

    puts("Activation url: " + activation_url)
    puts("Activation code: " + user_code)

    expect(device_code).not_to be_nil
    expect(user_code).not_to be_nil
  end

  it 'creates token' do
    response = subject.authorization

    expect(response['access_token']).not_to be_nil
    expect(response['refresh_token']).not_to be_nil
  end

  it 'updates token' do
    refresh_token = subject.config.data['refresh_token']

    response = subject.update_token(refresh_token)

    subject.config.save(response)

    ap response

    expect(response['access_token']).not_to be_nil
    expect(response['refresh_token']).not_to be_nil
  end

  it 'gets channels' do
    result = subject.get_channels

    #ap result

    expect(result['status_code']).to be 200
    expect(result['data'].size > 0).to be true

    result['data'].each do |value|
      puts value['name']
    end
  end

  it 'gets archive' do
    result = subject.get_archive(channel_id: 3)

    ap result

    expect(result['status_code']).to be 200
    expect(result['data']['media'].size > 0).to be true

    ap result['data']['media']
  end

  it 'gets genres' do
    result = subject.get_genres

    # ap result

    result['data'].each do |item|
      puts(item['id'])
      puts(item['name'])

      expect(result['status_code']).to be 200
      expect(result['data'].size > 0).to be true
    end
  end

  it 'gets blockbusters' do
    result = subject.get_blockbusters

    ap result

    result['data']['media'].each do |item|
      puts(item['type'])
      puts(item['id'])
      puts(item['name'])

      expect(result['status_code']).to be 200
      expect(result['data']['media'].size > 0).to be true
    end
  end

  it 'searches' do
    query = "news"
    result = subject.search(query: query)

    ap result

    expect(result['status_code']).to be 200
    expect(result['data'].size > 0).to be true
  end

  it 'tests pagination' do
    query = "news"
    result = subject.search(query: query, page: 1, per_page: 20)

    #ap result

    pagination = result['data']['pagination']

    expect(pagination['has_next']).to be true
    expect(pagination['has_previous']).to be false
    expect(pagination['page']).to eq 1

    result = subject.search(query: query, page: 2)

    #ap result

    pagination = result['data']['pagination']

    expect(pagination['has_next']).to be true
    expect(pagination['has_previous']).to be true
    expect(pagination['page']).to eq 2
  end

  it 'gets new arrivals' do
    result = subject.get_new_arrivals

    ap result

    expect(result['status_code']).to be 200
    expect(result['data'].size > 0).to be true
  end

  it 'gets url' do
    id = '580162' # 329678
    bitrate = '1200'
    format = 'mp4'

    url_data = subject.get_url(id, bitrate: bitrate, format: format, protocol: 'hls')

    puts('Media Url: ' + url_data[:url])

    #print('Play list:\n' + self.service.get_play_list(url_data['url']))
  end

  it 'gets media objects' do
    result = subject.get_archive(channel_id: 3)

    #print(json.dumps(result, indent=4))

    media_object = nil

    result['data']['media'].each do |item|
      type = item['type']

      if type == 'MediaObject'
        media_object = item
        break
      end
    end

    ap media_object

    bitrates = subject.bitrates(media_object['files'])

    if bitrates.keys.include? 'mp4'
      format = 'mp4'
    else
      format = 'wmv'
    end

    bitrate = bitrates[format][0]

    url_data = subject.get_url(media_object['id'], bitrate: bitrate, format: format)

    print_url_data(url_data, bitrates)

    new_url_data = subject.http_request(url: url_data[:url]).body

    puts new_url_data
  end

  it 'gets container' do
    result = subject.get_archive(channel_id: 5)

    ap result

    container = nil

    result['data']['media'].each do |item|
      type = item['type']

      if type == 'Container'
        container = item
        break
      end
    end

    #print(json.dumps(container, indent=4))

    children = subject.get_children(container['id'])

    #print(json.dumps(children, indent=4))

    first_media_object = nil

    children['data']['children'].each do |child|
      if child['type'] == 'MediaObject'
        first_media_object = child
      end
    end

    ap first_media_object

    bitrates = subject.bitrates(first_media_object[:files])

    bitrate = bitrates['mp4'][2]

    url_data = subject.get_url(first_media_object['id'], bitrate: bitrate, format: 'mp4')

    print_url_data(url_data, bitrates)
  end

  it 'gets bookmarks' do
    result = subject.get_bookmarks

    ap result

    expect(result['status_code']).to be 200
    expect(result['data'].size > 0).to be true
  end

  it 'gets folders' do
    result = subject.get_folders

    ap result

    expect(result['status_code']).to be 200
    expect(result['data'].size > 0).to be true
  end

  it 'gets bookmark' do
    bookmarks = subject.get_bookmarks

    bookmark = bookmarks['data']['bookmarks'][0]

    result = subject.get_bookmark(id=bookmark['id'])

    ap result

    expect(result['status_code']).to be 200
    expect(result['data'].size > 0).to be true
  end

  it 'gets topics' do
    EtvnetService::TOPICS.each do |topic|
      result = subject.get_topic_items(topic)

      ap result

      expect(result['status_code']).to be 200
      expect(result['data'].size > 0).to be true
    end
  end

  it 'gets video resolution' do
    puts subject.bitrate_to_resolution(1500)
  end

  it 'gets live channels' do
    result = subject.get_live_channels

    #ap result

    expect(result['status_code']).to be 200
    expect(result['data'].size > 0).to be true

    result['data'].each do |value|
      puts(value['id'])
      puts(value['name'])
      puts(value['icon'])
      puts(value['live_format'])
      puts(value['files'])
    end
  end

  it 'gets live schedule' do
    result = subject.get_live_channels
    channel = result['data'][0]

    result = subject.get_live_schedule(live_channel_id=channel['id'], date=Time.now)

    # ap result

    result['data'].each do |value|
      puts(value['rating'])
      puts(value['media_id'])
      puts(value['name'])
      puts(value['finish_time'])
      puts(value['start_time'])
      puts(value['current_show'])
      puts(value['categories'])
      puts(value['efir_week'])
      puts(value['channel'])
      puts(value['description'])
    end

    expect(result['status_code']).to be 200
    expect(result['data'].size > 0).to be true
  end

  it 'gets live categories' do
    result = subject.get_live_categories

    #print(json.dumps(result, indent=4))

    result['data'].each do |value|
      puts(value['id'])
      puts(value['name'])
    end

    expect(result['status_code']).to be 200
    expect(result['data'].size > 0).to be true
  end

  def print_url_data(url_data, bitrates)
    puts("Available bitrates:")

    if bitrates.keys.include? 'wmv'
      puts("wmv: " + bitrates['wmv'].join(' '))
    end

    if bitrates.keys.include? 'mp4'
      puts("mp4: " + bitrates['mp4'].join(' '))
    end

    puts('Format: ' + url_data[:format])
    puts('Bitrate: ' + url_data[:bitrate].to_s)
    puts('Protocol: ' + url_data[:protocol].to_s)

    puts('Media Url: ' + url_data[:url])
  end

end
