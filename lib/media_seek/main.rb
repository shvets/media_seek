require 'site/audio_knigi/audio_knigi_site'
require 'site/audioboo/audioboo_site'
require 'site/kino_kong/kino_kong_site'
require 'site/gid_online/gid_online_site'
require 'site/my_hit/my_hit_site'
require 'site/hdserials/hdserials_site'

class MediaSeek::Main

  def initialize site_name
    case site_name
      when 'audioknigi'
          @site = AudioKnigiSite.new
      when 'audioboo'
        @site = AudiobooSite.new
      when 'kino_kong'
        @site = KinoKongSite.new
      when 'gid_online'
        @site = GidOnlineSite.new
      when 'my_hit'
        @site = MyHitSite.new
      when 'hdserials'
        @site = HDSerialsSite.new
      else
        @site = AudioKnigiSite.new
    end
  end

  def search(query:, page: 1, page_size: 12)
    @site.search(query: query, page: page, page_size: page_size)
  end

  def navigate
    @site.navigate
  end
end
