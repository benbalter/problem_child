module ProblemChild
  class Memcache

    def self.client
      Dalli::Client.new(server, options)
    end

    def self.options
      {
       :username => ENV["MEMCACHIER_USERNAME"],
       :password => ENV["MEMCACHIER_PASSWORD"],
       :failover => true,
       :socket_timeout => 1.5,
       :socket_failure_delay => 0.2
      }
    end

    def self.server
      ENV["MEMCACHIER_SERVERS"].split(",") unless ENV["MEMCACHIER_SERVERS"].to_s.blank?
    end
  end
end
