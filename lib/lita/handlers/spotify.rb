require 'rspotify'
require 'rest_client'
require 'uri'

module Lita
  module Handlers
    class Spotify < Handler
      REDIS_KEY = 'spotify'
      REDIS_AUTH_CODE_KEY_SUFFIX = '-auth-code'
      config :client_id
      config :client_secret
      config :user
      config :playlist

      route(/^!spotify search artist (.*)/, :handle_artist_search)
      route(/^!spotify search track (.*)/, :handle_track_search)
      route(/^!spotify search album (.*)/, :handle_album_search)
      route(/^!spotify playlist add (track) (.*)/, :handle_playlist_add)
      route(/^!spotify auth/, :handle_auth)
      http.get '/spotify/authorize', :authorize
      route(/!get_uri/, :get_uri)

      def get_uri(username)
        uri = 'https://accounts.spotify.com/authorize/'
        # + '&state='
        uri += "?client_id=#{config.client_id}"\
              '&response_type=code'\
              "&redirect_uri=#{CGI.escape 'http://ec2-54-69-102-36.us-west-2.compute.amazonaws.com:8182/spotify/authorize'}"\
              "&scope=#{CGI.escape %w(playlist-read-private playlist-modify-public playlist-modify-private user-follow-modify user-follow-read user-library-read user-library-modify user-read-private user-read-email).join(' ')}"\
              '&show_dialog=true'\
              "&state=#{username}"
        uri
      end

      def handle_auth(response)
        uri = get_uri response.user.name
        Lita.logger.debug "Sending request to #{uri}"
        # response = RestClient.get(uri, { :params => {
        #                                  :client_id => config.client_id,
        #                                  :response_type => 'code',
        #                                  :redirect_uri => 'http://54.69.102.36:8182/spotify/authorize',
        #                                  :scope => %w(playlist-read-private playlist-modify-public playlist-modify-private user-follow-modify user-follow-read user-library-read user-library-modify user-read-private user-read-email).join(' ')
        #                                  }
        #                                }
        # ) { |response, request, result|
        #   Lita.logger.debug "HTTP request: #{request.url}"
        #   Lita.logger.debug "HTTP response code: #{response.code}"
        #   Lita.logger.debug "response: #{response.headers}"
        #   Lita.logger.debug "response body: #{response.to_str}"
        # }
        response.reply_privately uri
      end

      def authorize(request, response)
        Lita.logger.debug "Reached authorize.  request: #{request.inspect}, response: #{response.inspect}"
        query = Rack::Utils.parse_nested_query request.query_string
        Lita.logger.debug "query: #{query.inspect}"
        if query['code'].nil? and query['state'].nil?
          response.body << 'Parameter error!'
        else
          Lita.logger.debug "Setting redis key: #{REDIS_KEY}, #{query['state'] + REDIS_AUTH_CODE_KEY_SUFFIX}, #{query['code']}"
          redis.hset(REDIS_KEY, query['state'] + REDIS_AUTH_CODE_KEY_SUFFIX, query['code'])
          response.body << 'Code received.  You may return to the safety of IRC.'
        end
      end

      # def initialize(x)
      #   if config.client_id.nil? or config.client_secret.nil?
      #     raise 'config.handlers.spotify.client_id and config.handlers.spotify.client_secret must be specified.'
      #   end
      #   super(x)
      # end

      def handle_artist_search(response)
        search_term = response.matches[0][0]
        if artist = search_artists(search_term)
          response.reply "#{artist.name}, #{artist.popularity}%.  #{artist.external_urls['spotify']}"
        end
      end

      def handle_track_search(response)
        search_term = response.matches[0][0]
        if track = search_tracks(search_term).first
          artist_name = (track.artists.count > 0) ? track.artists.first.name : ''
          response.reply "#{artist_name} - #{track.name}.  #{track.external_urls['spotify']}"
        end
      end

      def handle_album_search(response)
        search_term = response.matches[0][0]
        if album = search_albums(search_term)
          artist_name = (album.artists.count > 0) ? album.artists.first.name : ''
          response.reply "#{artist_name} - #{album.name}.  #{album.external_urls['spotify']}"
        end
      end

      def handle_playlist_add(response)
        search_type = response.matches[0][0]
        search_term = response.matches[0][1]
        Lita.logger.debug "Using the search type and term #{search_type} and #{search_term}"
        Lita.logger.debug "Authenticating to Spotify with #{config.client_id} and #{config.client_secret}"
        RSpotify.authenticate(config.client_id, config.client_secret)
        spotify_user = RSpotify::User.new({'credentials' => redis.hget(REDIS_KEY, response.user.name + REDIS_AUTH_CODE_KEY_SUFFIX)})
        # user = RSpotify::User.find(config.user)
        Lita.logger.debug "Finding playlist with spotify user #{spotify_user.display_name} #{config.user} and #{config.playlist}"
        playlist = RSpotify::Playlist.find(config.user, config.playlist)

        case search_type
          when 'track'
            tracks = search_tracks search_term
        end

        # begin
          playlist.add_tracks!(tracks)
        # end

        response.reply "Added tracks #{tracks.collect { |t| t.name }.join ', '}"
      end

      def search_albums(term)
        albums = RSpotify::Album.search(term)
        if albums.count > 0
          albums.first
        end
      end

      def search_tracks(term)
        RSpotify::Track.search(term)
      end

      def search_artists(term)
        artists = RSpotify::Artist.search(term)
        if artists.count > 0
          artists.first
        end
      end

    end
    Lita.register_handler(Spotify)
  end
end
