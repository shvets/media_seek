require 'ap'
require 'common/downloader'
require 'site/audio_knigi/audio_knigi_service'
require 'site/audioboo/audioboo_service'

RSpec.describe Downloader do
  describe "audio_knigi_service" do
    let(:service) { AudioKnigiService.new }

    it 'downloads track' do
      query = 'пратчетт'

      books = service.search(query)

      book = books[:items][0]
      url = book[:path]
      tracks = service.get_audio_tracks(url)

      track = tracks[0]

      subject.download_file(url: track[:url], file_name: track[:name])
    end

    it 'downloads book' do
      query = 'пратчетт'

      books = service.search(query)

      book = books[:items][0]

      tracks = service.get_audio_tracks(book[:path])

      subject.download_book(book_name: book[:name], tracks: tracks)
    end
  end

  describe "audioboo_service" do
    let(:service) { AudiobooService.new }

    it 'downloads book' do
      query = 'пратчетт'

      books = service.search(query)

      book = books[0]

      tracks = service.get_audio_tracks(book[:path])

      subject.download_book(book_name: book[:name], tracks: tracks)
    end
  end
end