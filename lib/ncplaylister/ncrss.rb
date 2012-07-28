require 'rubygems'
require 'open-uri'
require 'nokogiri'

module NCRSS

  def self.fetch_new_items
    url = 'http://www.101x.com/_shared/blogs/RSS/blogrss.aspx?BlogID=1000395'
    @@feed ||= Nokogiri::HTML(open(url))
    items = extract_playlist_links(@@feed)
    write_seen_date
    items
  end

  private

  def self.extract_playlist_links(feed)
    cutoff = get_seen_date
    feed.xpath('//item')
      .reject{|i| !cutoff.nil? && get_date_from_feed_item(i) < cutoff}
      .compact
      .collect{|i| { :title => get_title_from_feed_item(i), :guid => get_guid_from_feed_item(i)} }
  end

  def self.write_seen_date
    File.open('timestamp', 'w'){|f| f.write(Time.now.to_s) }
  end

  def self.get_seen_date
    File.open('timestamp', 'r'){|f| Time.parse(f.read.gsub(/\n/,''))} if File.exists?('timestamp')
  end

  def self.get_date_from_feed_item(item)
    Time.parse(item.xpath('pubdate').first.content)
  end

  def self.get_guid_from_feed_item(item)
    item.xpath('guid').first.content
  end

  def self.get_title_from_feed_item(item)
    item.xpath('title').first.content
  end

end