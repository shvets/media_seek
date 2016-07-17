require 'ap'
require 'site/gid_online/gid_online_service'

RSpec.describe GidOnlineService do

  let(:document)  { subject.fetch_document(url: GidOnlineService::URL) }
  let(:all_movies) { subject.get_movies(document)[:items] }

  it 'gets genres' do
    result = subject.get_genres(document)

    ap result
  end

  it 'gets top links' do
    result = subject.get_top_links(document)

    ap result
  end

  it 'gets actors' do
    result = subject.get_actors(document)

    ap result
  end

  it 'gets actors by letter' do
    result = subject.get_actors(document, letter='А')

    ap result
  end

  it 'gets directors' do
    result = subject.get_directors(document)

    ap result
  end

  it 'gets directors by letter' do
    result = subject.get_directors(document, letter='В')

    ap result
  end

  it 'gets countries' do
    result = subject.get_countries(document)

    ap result
  end

  it 'gets years' do
    result = subject.get_years(document)

    ap result
  end

  it 'gets seasons' do
    result = subject.get_seasons('/2016/03/strazhi-galaktiki/')

    ap result
  end

  it 'gets episodes' do
    result = subject.get_episodes('/2016/03/strazhi-galaktiki')

    ap result
  end

  it 'parses movies page' do
    ap all_movies
  end

  it 'gets movies on genre page' do
    document = subject.fetch_document(url: GidOnlineService::URL + '/genre/vestern/')

    result = subject.get_movies(document, '/genre/vestern/')

    ap result
  end

  it 'gets movie url' do
    #movie_url = all_movies[1][:path]
    #
    # print(movie_url)

    movie_url = 'http://gidonline.club/2016/07/pomnish-menya/'

    urls = subject.retrieve_urls(movie_url)

    ap urls
  end

  it 'gets serials url' do
    movie_url = 'http://gidonline.club/2016/03/strazhi-galaktiki/'

    document = subject.get_movie_document(movie_url)

    serial_info = subject.get_serial_info(document)

    ap serial_info
  end

  it 'gets playlist' do
    movie_url = all_movies[1][:path]

    puts movie_url

    urls = subject.retrieve_urls(movie_url)

    ap urls

    play_list = subject.get_play_list(urls[2][:url])

    puts play_list
  end

  it 'gets media data' do
    movie_url = all_movies[0][:path]

    document = subject.fetch_document(url: movie_url)

    data = subject.get_media_data(document)

    ap data
  end

  it 'gets serials info' do
    movie_url = 'http://gidonline.club/2016/03/strazhi-galaktiki/'

    document = subject.get_movie_document(movie_url)

    serial_info = subject.get_serial_info(document)

    ap serial_info

    serial_info['seasons'].keys.each do |number|
      print(number)
      print(serial_info['seasons'][number])
    end
  end

  it 'searches' do
    query = 'красный'

    result = subject.search(query)

    ap result
  end

  it 'searches actors' do
    query = 'Аллен'

    result = subject.search_actors(document, query)

    ap result
  end

  it 'searches directors' do
    query = 'Люк'

    result = subject.search_directors(document, query)

    ap result
  end
end
