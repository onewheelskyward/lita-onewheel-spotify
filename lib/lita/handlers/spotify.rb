require 'rspotify'

module Lita
  module Handlers
    class Spotify < Handler
      route(/^!spotify search artist (.*)/, :handle_artist_search)
      route(/^!spotify search track (.*)/, :handle_track_search)
      route(/^!spotify search album (.*)/, :handle_album_search)

      def handle_artist_search(response)
        search_term = response.matches[0][0]
        artists = RSpotify::Artist.search(search_term)
        if artists.count > 0
          artist = artists.first
          response.reply "#{artist.name}, #{artist.popularity}%.  #{artist.external_urls['spotify']}"
        end
      end

      def handle_track_search(response)
        search_term = response.matches[0][0]
        tracks = RSpotify::Track.search(search_term)
        if tracks.count > 0
          track = tracks.first
          artist_name = (track.artists.count > 0) ? track.artists.first.name : ''
          response.reply "#{artist_name} - #{track.name}.  #{track.external_urls['spotify']}"
        end
      end

      def handle_album_search(response)
        search_term = response.matches[0][0]
        albums = RSpotify::Album.search(search_term)
        if albums.count > 0
          album = albums.first
          artist_name = (album.artists.count > 0) ? album.artists.first.name : ''
          response.reply "#{artist_name} - #{album.name}.  #{album.external_urls['spotify']}"
        end
      end

    end

    Lita.register_handler(Spotify)
  end
end
