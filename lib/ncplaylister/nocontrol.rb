require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'hallon'

class String
  def blank?
    self.gsub("\r\n", ' ').strip.length == 0
  end
end

class NoControl

  def self.test
    puts "Finding available playlists"
    playlists = NCRSS::fetch_new_items
    puts "No new playlists found" and return if playlists.empty?
    login_to_spotify
    playlists.each do |playlist|
      puts "Fetching playlist #{playlist[:title]}"
      playlist_track_list = Nokogiri::HTML(open(playlist[:guid]))
      track_list = extract_track_list(playlist_track_list)
      add_tracks_to_playlist(playlist[:title], find_spotify_tracks(track_list))
    end
  end

  private

  def self.extract_track_list(playlist)
    tracks = []
    playlist.css('#playlist tr').each do |tr|
      next if tr.css('.revminiheader').length > 0 || tr.css('td')[0].content.length < 2
      track = {
        :artist => tr.css('td')[0].content.gsub("\r\n", ' ').strip,
        :title => tr.css('td')[1].content.gsub("\r\n", ' ').strip,
        :album => tr.css('td')[2].content.gsub("\r\n", ' ').strip
      }
      tracks << track unless track[:artist].blank? or track[:title].blank? or track[:album].blank?
    end
    tracks
  end

  def self.login_to_spotify
    @session = Hallon::Session.initialize IO.read('./spotify_appkey.key')
    @session.login!('tgittos', 'dl7537')
  end

  def self.find_spotify_tracks(track_list)
    puts "Searching for tracks in playlist (this could take a while)"
    track_list.each_with_object([]) do |track, memo|
      result = Hallon::Search.new("#{track[:artist]} #{track[:title]}").load
      memo << Hallon::Track.new(result.tracks.first.to_link.to_str) unless result.tracks.total == 0
      sleep 0.1 # don't want to flood the API
    end
  end

  def self.add_tracks_to_playlist(name, tracks)
    puts "I want to put the tracks for #{name} into a playlist."
    print "What playlist can I put it in? (give Spotify playlist URI): "
    playlist_uri = gets.chomp
    spotify_playlist = Hallon::Playlist.new(playlist_uri).load
    spotify_playlist.insert(0, tracks)
    print "Uploading playlist..."
    spotify_playlist.upload
    puts "done"
  end

end