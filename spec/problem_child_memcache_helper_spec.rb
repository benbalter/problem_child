require "spec_helper"

describe "ProblemChild::MemcacheHelper" do

  class TestHelper
    extend ProblemChild::MemcacheHelper
  end

  it "knows the server" do
    with_env "MEMCACHIER_SERVERS", "localhost:1234" do
      expect(TestHelper.memcache_server).to eql(["localhost:1234"])
    end
  end

  it "can process multiple servers" do
    with_env "MEMCACHIER_SERVERS", "localhost:1234, localhost:4567" do
      expect(TestHelper.memcache_server).to eql(["localhost:1234", " localhost:4567"])
    end
  end

  it "pulls the username and password" do
    with_env "MEMCACHIER_USERNAME", "user" do
      with_env "MEMCACHIER_PASSWORD", "pass" do
        expected = {
                     :username => "user",
                     :password => "pass",
                     :failover => true,
                     :socket_timeout => 1.5,
                     :socket_failure_delay => 0.2
                   }
        expect(TestHelper.memcache_options).to eql(expected)
      end
    end
  end
end
