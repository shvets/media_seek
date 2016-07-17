require 'ap'
require 'site/audio_knigi/audio_knigi_service'

RSpec.describe AudioKnigiService do
  it 'gets author letters' do
    result = subject.get_authors_letters

    ap result
  end

  it 'gets performres letters' do
    result = subject.get_performers_letters

    ap result
  end

  it 'gets new books' do
    result = subject.get_new_books

    ap result
  end

  it 'gets best books by week' do
    result = subject.get_best_books period:'7'

    ap result
  end

  it 'gets best books by month' do
    result = subject.get_best_books period:'30'

    ap result
  end

  it 'gets best books by all' do
    result = subject.get_best_books period:'all'

    ap result
  end

  it 'gets author books' do
    result = subject.get_authors

    path = result[:items][0][:path]

    result = subject.get_books(path: path)

    ap result
  end

  it 'gets performer books' do
    result = subject.get_performers

    path = result[:items][0][:path]

    result = subject.get_books(path: path)

    ap result
  end

  it 'gets authors' do
    result = subject.get_authors

    ap result
  end

  it 'gets performers' do
    result = subject.get_performers

    ap result
  end

  it 'gets genres' do
    result = subject.get_genres(page: 1)

    ap result

    result = subject.get_genres(page: 2)

    ap result
  end

  it 'gets genre' do
    genres = subject.get_genres(page: 1)

    path = genres[:items][0][:path]

    result = subject.get_genre(path: path)

    ap result
  end

  it 'tests pagination' do
    result = subject.get_new_books(page: 1)

    ap result

    pagination = result[:pagination]

    expect(pagination[:has_next]).to eq(true)
    expect(pagination[:has_previous]).to eq(false)
    expect(pagination[:page]).to eq(1)

    result = subject.get_new_books(page: 2)

    ap result

    pagination = result[:pagination]

    expect(pagination[:has_next]).to eq(true)
    expect(pagination[:has_previous]).to eq(true)
    expect(pagination[:page]).to eq(2)
  end

  it 'gets audio tracks' do
    path = "http://audioknigi.club/alekseev-gleb-povesti-i-rasskazy"

    result = subject.get_audio_tracks(path)

    ap result
  end

  it 'tests search' do
    query = 'пратчетт'

    result = subject.search(query)

    ap result
  end

  # it 'tests generation' do
  #   result = subject.generate_authors_list('authors.json')
  #
  #   ap result
  # end

  it "tests grouping" do
    authors = JSON.parse(File.open("authors.json").read)

    authors = subject.group_items_by_letter(authors)

    ap authors
  end

end