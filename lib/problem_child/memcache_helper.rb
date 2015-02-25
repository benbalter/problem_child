module ProblemChild
  module MemcacheHelper
    def memcache_options
      {
       :username => ENV["MEMCACHIER_USERNAME"],
       :password => ENV["MEMCACHIER_PASSWORD"],
       :failover => true,
       :socket_timeout => 1.5,
       :socket_failure_delay => 0.2
      }
    end

    def memcache_server
      ENV["MEMCACHIER_SERVERS"].split(",") unless ENV["MEMCACHIER_SERVERS"].to_s.blank?
    end
  end
end
