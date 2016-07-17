# coding: utf-8

require 'uri'
require 'json'
require "base64"
require 'ruby-progressbar'

require 'common/http_service'

class MyHitService < HttpService
  URL = 'https://my-hit.org'

end
