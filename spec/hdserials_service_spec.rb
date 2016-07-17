require 'ap'
require 'site/hdserials/hdserials_service'

RSpec.describe HDSerialsService do

  it 'gets categories' do
    menu_items = subject.get_categories

    menu_items.each do |item|
      expect(item[:path].size > 0).to equal(true)
      expect(item[:title].size > 0).to equal(true)
    end
  end

  it 'gets new series' do
    menu_items = subject.get_new_series

    menu_items.each do |item|
      expect(item[:path].size > 0).to equal(true)
      expect(item[:title].size > 0).to equal(true)
    end
  end

  it 'gets popular' do
    response = subject.get_popular

    response[:items].each do |item|
      expect(item[:path].size > 0).to equal(true)
      expect(item[:title].size > 0).to equal(true)
      expect(item[:thumb].size > 0).to equal(true)
    end
  end

  it 'gets subcategories' do
    response = subject.get_subcategories('/Filmy.html')

    response[:data].each do |item|
      expect(item[:path].size > 0).to equal(true)
      expect(item[:title].size > 0).to equal(true)
    end
  end

  it 'gets category items' do
    response = subject.get_category_items('/Filmy.html')

    response[:items].each do |item|
      expect(item[:path].size > 0).to equal(true)
      expect(item[:title].size > 0).to equal(true)
      expect(item[:thumb].size > 0).to equal(true)
    end
  end

  it 'searches' do
    query = 'castle'

    result = subject.search(query)

    ap result
  end

  it 'gets pagination in category items' do
    result = subject.get_category_items('/Filmy.html', page=1)

    pagination = result[:pagination]

    expect(pagination[:has_next]).to equal(true)
    expect(pagination[:has_previous]).to equal(false)
    expect(pagination[:page]).to equal(1)

    result = subject.get_category_items('/Filmy.html', page=2)

    pagination = result[:pagination]

    expect(pagination[:has_next]).to equal(true)
    expect(pagination[:has_previous]).to equal(true)
    expect(pagination[:page]).to equal(2)
  end

  it 'gets pagination in popular' do
    result = subject.get_popular(page=1)

    pagination = result[:pagination]

    expect(pagination[:has_next]).to equal(true)
    expect(pagination[:has_previous]).to equal(false)
    expect(pagination[:page]).to equal(1)

    result = subject.get_popular(page=2)

    pagination = result[:pagination]

    expect(pagination[:has_next]).to equal(true)
    expect(pagination[:has_previous]).to equal(true)
    expect(pagination[:page]).to equal(2)
  end

  it 'gets pagination in subcategories' do
    path = '/Serialy.html'

    result = subject.get_subcategories(path=path, page=1)

    pagination = result[:pagination]

    expect(pagination[:has_next]).to equal(true)
    expect(pagination[:has_previous]).to equal(false)
    expect(pagination[:page]).to equal(1)

    result = subject.get_subcategories(path=path, page=2)

    pagination = result[:pagination]

    expect(pagination[:has_next]).to equal(true)
    expect(pagination[:has_previous]).to equal(true)
    expect(pagination[:page]).to equal(2)
  end

  it 'gets media data' do
    new_series = subject.get_new_series

    path = new_series[0][:path]

    document = subject.fetch_document(url: path)

    data = subject.get_media_data(document)

    ap data

    expect(data['rating'] > 0).to equal(true)
    expect(data['title'].size > 0).to equal(true)
    expect(data['thumb'].size > 0).to equal(true)
  end

  #             def test_retrieve_urls(self):
  #                 new_series = self.service.get_new_series()
  #
  #             path = new_series[0]['path']
  #
  #             urls = self.service.retrieve_urls(path)
  #
  #             print(json.dumps(urls, indent=4))
  #
  #             def test_retrieve_episode_urls(self):
  #                 new_series = self.service.get_new_series()
  #
  #             path = new_series[0]['path']
  #
  #             urls = self.service.retrieve_urls(path, season=1, episode=2)
  #
  #             print(json.dumps(urls, indent=4))
  #
  #             def test_get_play_list(self):
  #                 new_series = self.service.get_new_series()
  #
  #             path = new_series[0]['path']
  #
  #             urls = self.service.retrieve_urls(path)
  #
  #             play_list = self.service.get_play_list(urls[0]['url'])
  #
  #             print(play_list)
  #
  #             def test_get_episode_info(self):
  #                 new_series = self.service.get_new_series()
  #
  #             text = new_series[0]['text']
  #
  #             print text
  #
  #             result = self.service.get_episode_info(text)
  #
  #             print(json.dumps(result, indent=4))
  #
  #             def test_is_serial(self):
  #                 new_series = self.service.get_new_series()
  #
  #             path = new_series[0]['path']
  #
  #             result = self.service.is_serial(path)
  #
  #             print(json.dumps(result, indent=4))
  #
  #             def test_get_movie_documents(self):
  #                 path = 'http://www.hdserials.tv/Serialy/Bulvarnye-uzhasy-/-Penny-Dreadful/Bulvarnye-uzhasy-/-Strashnye-skazki-/-Penny-Dreadful.html'
  #
  #             result = self.service.get_movie_documents(path)
  #
  #             print(result)
  #
  #             def test_convert_duration(self):
  #                 text = u' ~  22 мин'
  #
  #             result = self.service.convert_duration(text)
  #
  #             print result

end
