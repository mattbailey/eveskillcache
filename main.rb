#!/usr/bin/env ruby

require 'sucker_punch'
require 'hiredis'
require 'em-synchrony'
require 'redis'
require 'yaml'
require 'ohm'
require 'pry'


# Load models
Dir[File.dirname(__FILE__) + '/models/*.rb'].each { |file| require file }

# Load Eve Workloads
Dir[File.dirname(__FILE__) + '/workloads/eve/*.rb'].each { |file| require file }

Ohm.redis = Redic.new("redis://127.0.0.1:6379")

EveJobs::CacheSkillIDs.new.perform

Eveuser.all.each do |user|
  if user.enabled
    EveJobs::CacheUserAccounts.new.perform(user.name)
  end
end
