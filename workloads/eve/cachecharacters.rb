require 'eaal'
require 'time'
ENV['TZ'] = 'UTC'
EAAL.cache = EAAL::Cache::FileCache.new

def seconds_to_units(seconds)
  '%dd %dh %dm %ds' %
    # the .reverse lets us put the larger units first for readability
    [24,60,60].reverse.inject([seconds]) {|result, unitsize|
      result[0,0] = result.shift.divmod(unitsize)
      result
    }
end

module EveJobs
  class CacheSkillIDs
    include SuckerPunch::Job

    def perform
      r = Redis.new
      EAAL::API.new(nil, nil, 'eve').SkillTree.skillGroups.each do |group|
        group.container['skills'].each do |skill|
          group.container['skills'].each do |skill|
            r.hset("weechat:eve:skills", skill.typeID, skill.typeName)
          end
        end
      end
    end
  end
  class CacheCharacter
    include SuckerPunch::Job

    def perform(user, keyid, vcode, cid, name)
      training = EAAL::API.new(keyid, vcode, 'char').skillInTraining(characterID: cid)
      if training.skillInTraining == '1'
        skill = training.trainingTypeID
        level = training.trainingToLevel
        finish = seconds_to_units(Time.parse(training.trainingEndTime) - Time.now)
        queue = EAAL::API.new(keyid, vcode, 'char').SkillQueue(characterID: cid).skillqueue
        qfinish = seconds_to_units(Time.parse(queue.last.endTime) - Time.now)
        qlength = queue.size
      else
        skill = nil
        level = nil
        finish = nil
      end
      r = Redis.new
      r.hset("weechat:eve:#{user}", name, "#{name} | S: #{skill} #{level} - #{finish} | Q: #{qlength} - #{qfinish}")
    end
  end
  class CacheAccount
    include SuckerPunch::Job

    def perform(user, keyid, vcode)
      begin
        EAAL::API.new(keyid, vcode, 'account').Characters.characters.each do |c|
          CacheCharacter.new.perform(user, keyid, vcode, c.characterID, c.name)
        end
      rescue EAAL::Exception::HTTPError => e
        if e.message.match('error code="222"')
          Evekeypair.find(keyid: keyid, vcode: vcode).first.delete
        end
      end
    end
  end
  class CacheUserAccounts
    include SuckerPunch::Job

    def perform(user)
      Eveuser.find(name: user).first.evekeypairs.each do |keypair|
        CacheAccount.new.perform(user, keypair.keyid, keypair.vcode)
      end
    end
  end
end
