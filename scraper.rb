#!/usr/bin/env ruby

require 'rubygems'
require 'bundler'
Bundler.setup

require 'rest_client'
require 'RedCloth'
require 'crack/xml'
require 'erb'

class Mingle

  def initialize
    @protocol = "https"
    @base_url = "discovery.mingle.thoughtworks.com"
    @user_name = "prasann"
    @password = "password123."
    @api_url = @base_url << "/api/v2/projects/discovery___pass_manager_new"
  end

  def get_all_cards(page)
    p "Collecting Data from mingle for page : #{page}"
    xml = RestClient.get "#{@protocol}://#{@user_name}:#{@password}@#{@api_url}/cards.xml?filters[]=[Type][is][story]&filters[]=[Type][is][Tech%20Task]&page=#{page}"
    #xml = RestClient.get 'http://prasanna.local:8000/cards.xml'
    xml_obj = Crack::XML.parse(xml)
    p "Done with page : #{page}"
    xml_obj["cards"].collect { |card_xml| Card.new(card_xml, self) }
  end
end

class Card

  def initialize(xml, mingle)
    @xml = xml
    @mingle = mingle
  end

  def description
    RedCloth.new(@xml["description"]).to_html unless @xml["description"].nil?
  end

  def release_name
    release_card = self.property("Release")
    release_card && release_card.name
  end

  def property(name='Internal System(s) involved')
    match = self.properties.find { |prop| prop["name"].downcase == name.downcase }
    return match.nil? unless match
    if match["type_description"] =~ /card/i
      match["value"] && @mingle.get_card(match["value"]["number"])
    else
      match["value"]
    end
  end

  def method_missing(method_name, *args)
    @xml.has_key?(method_name.to_s) ? @xml[method_name.to_s] : super
  end
end

class Scraper
  def self.scrape
    mingle = Mingle.new
    cards = (1..5).collect { |page| mingle.get_all_cards(page) }.flatten
    html = ERB.new(File.read('result.html.erb')).result({:cards => cards}.instance_eval { binding })
    File.open("document.html", "w+") { |f| f.write(html) }
  end
end

Scraper.scrape

