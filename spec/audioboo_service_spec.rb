require 'ap'
require 'site/audioboo/audioboo_service'

RSpec.describe AudiobooService do
  it 'gets letters' do
    result = subject.get_letters

    ap result
  end

  it 'gets authors by the letter' do
    letters = subject.get_letters

    result = subject.get_authors_by_letter(letters[0][:path])

    ap result
  end

  it 'gets author books' do
    letters = subject.get_letters

    authors = subject.get_authors_by_letter(letters[0][:path])

    result = subject.get_author_books(authors[authors.keys[1]][0][:path])

    ap result
  end

  it 'gets playlist urls' do
    letters = subject.get_letters

    authors = subject.get_authors_by_letter(letters[0][:path])

    books_url = authors[authors.keys[1]][0][:path]

    books = subject.get_author_books(books_url)

    book_url = books[1][:path]

    playlist_urls = subject.get_playlist_urls(book_url)

    ap playlist_urls
  end

  it 'gets audio tracks' do
    letters = subject.get_letters

    authors = subject.get_authors_by_letter(letters[0][:path])

    books_url = authors[authors.keys[1]][0][:path]

    books = subject.get_author_books(books_url)

    book_url = books[1][:path]

    result = subject.get_audio_tracks(book_url)

    ap result
  end

  it 'searches items' do
    query = 'пратчетт'

    result = subject.search(query)

    ap result
  end

  # it 'converts track duration' do
  #   s = "14:46"
  #
  #   result = subject.convert_track_duration(s)
  #
  #   print(result)
  # end
end
