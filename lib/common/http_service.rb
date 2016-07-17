require 'json'
require 'nokogiri'
require 'resource_accessor'
require 'net/http'
require 'uri'

class HttpService
  attr_reader :accessor

  def initialize
    @accessor = ResourceAccessor.new
  end

  def build_url(path, **params)
    path + "?" + params.to_a.map { |x| "#{x[0]}=#{x[1]}" }.join("&")
  end

  def http_request(url:, headers: {}, query: {}, data: {}, method: :get)
    accessor.get_response({url: url, method: method, query: query, body: data}, headers)
  end

  def fetch_content(url:, headers: {})
      http_request(url: url, headers: headers).body
  end

  def fetch_document(url:, headers: {}, encoding: nil)
    content = fetch_content(url: url, headers: headers)

    to_document(content, encoding=encoding)
  end

  def to_document(buffer, encoding=nil)
    Nokogiri::HTML(buffer, nil, encoding)
  end

  def to_json(buffer)
    unless buffer
      buffer = "{}"
    end

    JSON.parse(buffer)
  end

  def get_play_list(url, base_url=nil)
    unless base_url
      base_url = get_base_url(url)
    end

    response = http_request(url: url)

    lines = StringIO.new(response.body).readlines

    new_lines = StringIO.new

    lines.each do |line|
      if line[0] == '#'
        new_lines.write(line)
      else
        new_lines.write(base_url + '/' + line)
      end
    end

    new_lines.string
  end

  def get_base_url(url)
    path = url.split('/')
    path.pop

    path.join('/')
  end
end
