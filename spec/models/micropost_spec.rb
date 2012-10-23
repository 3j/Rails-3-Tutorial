require 'spec_helper'

describe Micropost do

  let(:user) { FactoryGirl.create :user }

  before do
    @micropost = user.microposts.build content: "Lorem ipsum"
  end

  subject { @micropost }

  it { should respond_to :content }
  it { should respond_to :user_id }
  it { should respond_to :user }

  it { should be_valid }

  it "should belong to the right user" do
    expect(@micropost.user).to eq user
  end

  describe "accessible attributes" do
    it "should not allow access to user_id" do
      expect { Micropost.new user_id: user.id }.
        to raise_error ActiveModel::MassAssignmentSecurity::Error
    end
  end
  
  describe "when user_id is not present" do
    before { @micropost.user_id = nil }
    it { should_not be_valid }
  end

  describe "with blank content" do
    before { @micropost.content = '' }
    it { should_not be_valid }
  end

  describe "with too long content" do
    before { @micropost.content = 'a' * 141 }
    it { should_not be_valid }
  end
end
