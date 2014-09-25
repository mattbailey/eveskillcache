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

allkeys = YAML.load_file('bla.yml')
allkeys.keys.each do |name|
  user = Eveuser.create(name: name, enabled: true)
  allkeys[name].each do |pair|
    keypair = Evekeypair.create(keyid: pair[:id], vcode: pair[:vcode])
    keypair.eveuser=user
    keypair.save
    user.save
  end
end
