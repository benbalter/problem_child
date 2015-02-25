require "spec_helper"

describe "ProblemChild::RedisHelper" do
  class TestHelper
    extend ProblemChild::RedisHelper
  end

  it "init's redis" do
    expect(TestHelper.init_redis!.class).to eql(Redis)
  end
end
