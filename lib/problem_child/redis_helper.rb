module ProblemChild
  module RedisHelper
    def init_redis!
      uri = URI.parse(ENV["REDISTOGO_URL"] || "redis://127.0.0.1:6379")
      @@redis = Redis.new(:host => uri.host, :port => uri.port,:password => uri.password)
    end
  end
end
