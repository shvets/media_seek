require 'ruby-progressbar'
require 'net/http'
require 'uri'
require 'fiber'

class Downloader
  def download_book(book_name:, tracks:)
    FileUtils.mkdir_p(book_name)

    tracks.each do |track|
      url = track[:url]
      file_name = book_name + '/' + track[:name]

      url_base = url.split('/')[2]
      url_path = '/'+url.split('/')[3..-1].join('/')

      Net::HTTP.start(url_base) do |http|
        response = http.request_head(URI.escape(url_path))

        if response.class == Net::HTTPFound
          new_url = response['location']

          download_file(url: new_url, file_name: file_name)
        else
          download_stream(url_path, file_name, http, response['content-length'].to_i)
        end
      end
    end
  end

  def download_movie(url:, name:)
    download_file(url: url, file_name: name)
  end

  def download_season(serie_name:, season_name:, playlist:)
    FileUtils.mkdir_p(serie_name + '/' + season_name)

    playlist.each do |item|
      files = item[:file]

      if files.size > 1
        url = files[files.size-1]
      else
        url = files[0]
      end

      index = url.rindex('/')
      name = url[index+1..-1]

      file_name = serie_name + '/' + season_name + '/' + name

      download_movie(url: item[:file][0], name: file_name)
      #break
    end
  end

  def download_file(url:, file_name:)
    url_base = url.split('/')[2]
    url_path = '/'+url.split('/')[3..-1].join('/')

    Net::HTTP.start(url_base) do |http|
      response = http.request_head(URI.escape(url_path))

      download_stream(url_path, file_name, http, response['content-length'].to_i)
    end
  end

  def download_stream url_path, file_name, http, stream_size
    file_size = File.exist?(file_name) ? File.size(file_name) : 0

    if stream_size > 0 and stream_size == file_size
      puts file_name + ": already exists."
    else
      progressbar = ProgressBar.create(title: file_name)
      progressbar.total = stream_size

      File.open(file_name, 'wb') do |file|
        counter = 0

        http.get(URI.escape(url_path)) do |bytes|
          file.write bytes

          counter += bytes.length

          if progressbar.total > counter
            progressbar.progress = counter
          end
        end
      end

      progressbar.finish
    end
  end
end