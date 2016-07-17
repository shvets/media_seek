require 'common/http_service'

class AuthService < HttpService
  def initialize(auth_url, client_id, client_secret, grant_type, scope)
    @auth_url = auth_url
    @client_id = client_id
    @client_secret = client_secret
    @grant_type = grant_type
    @scope = scope

    super()
  end

  def get_activation_codes(include_client_secret=true, include_client_id=false)
    data = {'scope': @scope}

    if include_client_secret
      data[:client_secret] = @client_secret
    end

    if include_client_id
      data[:client_id] = @client_id
    end

    response = auth_request(data, 'device/code')

    result = JSON.parse(response.body)

    result[:activation_url] = @auth_url + 'device/usercode'

    result
  end

  def create_token(device_code)
    data = {grant_type: @grant_type, code: device_code}

    response = auth_request(data)


    add_expires(JSON.parse(response.body))
  end

  def update_token(refresh_token)
    data = {grant_type: 'refresh_token', refresh_token: refresh_token}

    response = auth_request(data)

    add_expires(JSON.parse(response.body))
  end

  def auth_request(query, rtype='token', method=nil)
    query[:client_id] = @client_id

    if rtype == 'token'
      query[:client_secret] = @client_secret
    end

    url = @auth_url + rtype

    http_request(url: url, query: query, method: method)
  end

  def add_expires(data)
    if data['expires_in']
      data['expires'] = Time.now.to_i + data['expires_in'].to_i
    end

    data
  end
end