require 'spec_helper'

describe Relationship do

  let(:follower) { FactoryGirl.create :user }
  let(:followed) { FactoryGirl.create :user }
  let(:relationship) { follower.relationships.build followed_id: followed.id }

  subject { relationship }
  
  it { should be_valid }

  describe "accessible attributes" do
    it "should not allow access to follower_id" do
      expect { Relationship.new follower_id: follower.id }.
        to raise_error ActiveModel::MassAssignmentSecurity::Error
    end
  end

  describe "follower methods" do
    it { should respond_to :follower }
    it "should have the right follower user" do
      expect(relationship.follower).to eq follower
    end
    
    it { should respond_to :followed }
    it "should have the right followed user" do
      expect(relationship.followed).to eq followed
    end
  end
  
  describe "when follower id is not present" do
    before { relationship.follower_id = nil }
    it { should_not be_valid }
  end

  describe "when followed id is not present" do
    before { relationship.followed_id = nil }
    it { should_not be_valid }
  end
end
