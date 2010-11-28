require "lighthouse-api"

LIGHTHOUSE_PROJECT_ID   = 12345 # Your lighthouse project ID 
Lighthouse.account      = "some_lightouse_account"
Lighthouse.token        = "5553af9c7f604a4ed936227d7014f3a25e7f17f2"

class Mingle < ActiveResource::Base
  
  # Tags in mingle you'd like to be translated to Lighthouse
  LIGHTHOUSE_SHARED_TAGS = %w( important very\ important desktop testing client javascript )
  
  # A map between statuses of lighthouse and mingle, could look something what's below
  LIGHTHOUSE_STATUS_MAP = [ ["Ready for Development", "new"], ["In Development","open"], ["Fixed Not Pushed", "resolved"], ["Blocked", "hold"], ["Ready for Testing", "qa",], ["Closed", "closed"] ]
  
  class << self
    attr_accessor :api_version, :project
  end
  
  @project          = "project"
  self.user         = "mingle_user"
  self.password     = "1a2b3c"
  
  # Your Mingle installation's API location
  @api_version      = 2
  self.site         = "http://some-mingle-site.com:9000/api/v#{@api_version}/projects/#{@project}/"
  self.card_url     = "http://some-mingle-site.com:9000/projects/#{@project}/cards/"
  
  Mingle.logger     = Logger.new("#{RAILS_ROOT}/log/mingle.log")

  class Card < Mingle
  end
end