require_relative 'auth_service'

class ApiService < AuthService
  attr_reader :config

  def initialize(config, api_url, user_agent, auth_url, client_id, client_secret, grant_type, scope)
    @config = config
    @config.load

    @api_url = api_url
    @user_agent = user_agent

    super(auth_url, client_id, client_secret, grant_type, scope)
  end

  def reset_token
    config.delete('access_token')
    config.delete('refresh_token')
    config.delete('device_code')
    config.delete('user_code')

    @config.save
  end

  def api_request(base_url, path, method=nil, headers=nil, data=nil, *a, **k)
    unless headers
      headers = {}
    end

    url = base_url + path

    unless headers
      headers = {}
    end

    headers['User-agent'] = @user_agent

    http_request(url: url, headers: headers, data: data, method: method)
  end

  def authorization(on_authorization_success=nil, on_authorization_failure=nil, include_client_secret=true)
    unless on_authorization_success
      on_authorization_success = lambda { @on_authorization_success }
    end

    unless on_authorization_failure
      on_authorization_failure = lambda { @on_authorization_failure }
    end

    if check_access_data('device_code') and check_access_data('user_code')
      activation_url = @config.data[:activation_url]
      user_code = @config.data['user_code']
      device_code = @config.data['device_code']
    else
      ac_response = get_activation_codes(include_client_secret=include_client_secret)

      activation_url = ac_response[:activation_url]
      user_code = ac_response['user_code']
      device_code = ac_response['device_code']

      @config.save({
                       "user_code": user_code,
                       "device_code": device_code,
                       "activation_url": activation_url
                   })
    end

    if user_code
      result = on_authorization_success(user_code, device_code, activation_url)
    else
      result = on_authorization_failure
    end

    result
  end

  def on_authorization_success(user_code, device_code, activation_url)
    nil
  end

  def on_authorization_failure
    nil
  end

  def check_access_data(key)
    if key == 'device_code'
      @config.data[key]
    else
      @config.data[key] and @config.data['expires'] and @config.data['expires'] >= Time.now.to_i
    end
  end

  def check_token
    begin
      if check_access_data('access_token')
        true
      elsif @config.data['refresh_token']
        refresh_token = @config.data['refresh_token']

        response = update_token(refresh_token)

        config.save(response)

        true
      elsif check_access_data('device_code')
        device_code = @config.data['device_code']

        response = create_token(device_code=device_code)

        response['device_code'] = device_code

        config.save(response)

        false
      else
        false
      end

    rescue Net::HTTPError => e
      puts(e)

      if e.code == 400
        reset_token
      end

      false
    end
  end

  def full_request(path, method: nil, data: nil, unauthorized: false)
    unless check_token
      authorization
    end

    result = nil

    begin
      access_token = @config.data['access_token']

      access_path = path + (path.index('?') ? '&' : '?') + "access_token=#{access_token}"

      response = api_request(@api_url, access_path, method, data)

      result = response.body
    rescue Net::HTTPError => e
      if e.code == 401 and not unauthorized
        #or e.code == 400:
        refresh_token = @config.data['refresh_token']

        response = update_token(refresh_token)

        if response
          @config.save(response)

          result = full_request(path, method, data, unauthorized=True, *a, **k)
        else
          puts('error')
        end
      else
        puts(e)
      end
    end

    result
  end
end
