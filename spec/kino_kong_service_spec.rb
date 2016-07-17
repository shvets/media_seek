require 'ap'
require 'site/kino_kong/kino_kong_service'

RSpec.describe KinoKongService do
  it 'gets all movies' do
    result = subject.get_all_movies

    ap result
  end

  it 'gets urls' do
    path = "/26545-lovushka-dlya-privideniya-2015-smotret-online.html"

    result = subject.get_urls(KinoKongService::URL+path)

    ap result
  end

  it 'searches' do
    query = 'красный'

    result = subject.search(query)

    ap result
  end

  it 'gets serial info' do
    series = subject.get_all_series[:items]

    path = series[0][:path]

    result = subject.get_serie_info(KinoKongService::URL+path)

    ap result
  end

  it 'gets grouped genres' do
    result = subject.get_grouped_genres

    ap result
  end

  # it 'gets urls metadata' do
  #   path = "/26545-lovushka-dlya-privideniya-2015-smotret-online.html"
  #
  #   urls = subject.get_urls(path)
  #
  #   result = subject.get_urls_metadata(urls)
  #
  #   ap result
  # end

  it 'tests pagination in all movies' do
    result = subject.get_all_movies(page=1)

    pagination = result[:pagination]

    expect(pagination[:has_next]).to equal(true)
    expect(pagination[:has_previous]).to equal(false)
    expect(pagination[:page]).to equal(1)

    result = subject.get_all_movies(page=2)

    pagination = result[:pagination]

    expect(pagination[:has_next]).to equal(true)
    expect(pagination[:has_previous]).to equal(true)
    expect(pagination[:page]).to equal(2)
  end

  it 'gets movies by rating' do
    result = subject.get_movies_by_rating

    ap result
  end

  it 'gets tags' do
    result = subject.get_tags

    ap result
  end

  it 'gets soundtracks' do
    path = '/15479-smotret-dedpul-2016-smotet-online.html'

    result = subject.get_serie_info(KinoKongService::URL+path)

    ap result
  end

end
