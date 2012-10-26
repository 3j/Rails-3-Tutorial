require 'spec_helper'


describe "User Pages" do
  subject { page }

  describe "index" do
    let(:user) { FactoryGirl.create :user }
    before do
      sign_in user 
      visit users_path
    end

    describe "page" do
      it { should have_selector 'title', text: 'All users' }
      it { should have_selector 'h1', text: 'All users' }

      describe "as a regular user" do
        it { should_not have_link 'delete' }
      end

      describe "as an admin user" do
        let(:admin) { FactoryGirl.create :admin }
        before do
          sign_in admin
          visit users_path
        end
            
        it "should have link 'delete' for other users" do
          page.should have_link 'delete', href: user_path(User.first)
        end

        it "should not have link 'delete' for himself" do
          page.should_not have_link 'delete', href: user_path(admin)
        end
        
        it "should be able to delete another user" do
          expect { click_link 'delete' }.to change(User, :count).by -1
        end

        describe "after deleting another user" do
          before { click_link 'delete' }

          it { should have_selector 'title', text: 'All users' }
          it { should have_selector 'div.alert.alert-success' }
        end
      end
    end
    
    describe "pagination" do
      before(:all) { 30.times { FactoryGirl.create :user } }
      after(:all) { User.delete_all }

      it { should have_selector 'div.pagination' }

      it "should list each user" do
        User.paginate(page: 1).each do |user|
          expect(page).to have_selector 'li>a', text: user.name
        end
      end
    end
  end

  describe "profile" do
    let(:user) { FactoryGirl.create :user }
    let!(:micropost1) { FactoryGirl.create :micropost, user: user, content: "Foo" }
    let!(:micropost2) { FactoryGirl.create :micropost, user: user, content: "Bar" }
    before { visit user_path user }

    describe "page" do
      it { should have_selector 'h1', text: user.name }
      it { should have_selector 'title', text: user.name }

      describe "microposts" do
        it { should have_content micropost1.content }
        it { should have_content micropost2.content }
        it { should have_content user.microposts.count }
      end

      describe "follow/unfollow buttons" do
        let(:other_user) { FactoryGirl.create :user }
        before { sign_in user }

        describe "following a user" do
          before { visit user_path other_user }

          it "should increment the followed user count" do
            expect { click_button "Follow" }.
              to change(user.followed_users, :count).by 1
          end

          it "should increment the other user's followers count" do
            expect { click_button "Follow" }.
              to change(other_user.followers, :count).by 1
          end

          describe "toggling the button" do
            before { click_button "Follow" }
            it { should have_selector 'input', value: 'Unfollow' }
          end
        end

        describe "unfollowing a user" do
          before do
            user.follow! other_user
            visit user_path other_user
          end

          it "should decrement the followed user count" do
            expect { click_button "Unfollow" }.
              to change(user.followed_users, :count).by -1
          end

          it "should decrement the other user's followers count" do
            expect { click_button "Unfollow" }.
              to change(other_user.followers, :count).by -1
          end

          describe "toggling the button" do
            before { click_button "Unfollow" }
            it { should have_selector 'input', value: 'Follow' }
          end
        end
      end
    end

    describe "pagination" do
      before(:all) do
        30.times { FactoryGirl.create :micropost, user: user, content: "Foo" }
      end
      after(:all) { user.delete }

      it { should have_selector 'div.pagination' }

      it "should list each micropost from current user" do
        user.microposts.paginate(page: 1).each do |micropost|
          expect(page).to have_selector 'span.content', text: micropost.content
        end
      end
    end
  end

  describe "signup" do
    let(:submit) { "Create my account" }
    before { visit signup_path }

    describe "page" do
      it { should have_selector 'h1', text: 'Sign up' }
      it { should have_selector 'title', text: "Sign up" }
    end

    describe "with valid user information" do
      before do
        fill_in "Name", with: "Example User"
        fill_in "Email", with: "user@example.com"
        fill_in "Password", with: "foobar"
        fill_in "Confirmation", with: "foobar"
      end

      it "should create a user" do
        expect { click_button submit }.to change(User, :count).by 1
      end

      describe "after saving the user" do
        before { click_button submit }
        let(:user) { User.find_by_email 'user@example.com' }

        it { should have_selector 'title', text: user.name }
        it { should have_selector 'div.alert.alert-success', text: 'Welcome' }
        it { should have_link 'Sign out' }
      end
    end

    describe "with invalid information" do
      it "should not create a user" do
        expect { click_button submit }.not_to change(User, :count).by 1
      end

      describe "after submission" do
        before { click_button submit }

        it { should have_selector 'title', text: 'Sign up' }
        it { should have_content 'error' }
        it { should_not have_content 'Password digest' }
      end
    end
  end

  describe "edit" do
    let(:user) { FactoryGirl.create :user }
    before do
      sign_in user
      visit edit_user_path user
    end

    describe "page" do
      it { should have_selector 'h1', text: "Update your profile" }
      it { should have_selector 'title', text: "Edit user" }
      it { should have_link 'change', href: 'http://gravatar.com/emails' }
    end

    describe "with valid information" do
      let(:new_name) { "New Name" }
      let(:new_email) { "new@example.org" }
      before do
        fill_in "Name", with: new_name
        fill_in "Email", with: new_email
        fill_in "Password", with: user.password
        fill_in "Confirmation", with: user.password
        click_button "Save changes"
      end

      it { should have_selector 'title', text: new_name }
      it { should have_link 'Sign out', href: signout_path }
      it { should have_css 'div.alert.alert-success' }

      it "should update the user's edited data in the database" do
        expect(user.reload.name).to eq new_name
        expect(user.reload.email).to eq new_email
      end
    end

    describe "with invalid information" do
      before { click_button "Save changes" }
      it { should have_content 'error' }
    end
  end

  describe "following/followers" do
    let(:user) { FactoryGirl.create :user }
    let(:other_user) { FactoryGirl.create :user }
    before { user.follow! other_user }

    describe "followed users" do
      before do
        sign_in user
        visit following_user_path user
      end

      it { should have_selector 'title', text: full_title('Following') }
      it { should have_selector 'h3', text: 'Following' }
      it "should has link to the followed user" do
        page.should have_link other_user.name, href: user_path(other_user)
      end
    end

    describe "followers" do
      before do
        sign_in other_user
        visit followers_user_path other_user
      end

      it { should have_selector 'title', text: full_title('Followers') }
      it { should have_selector 'h3', text: 'Followers' }
      it { should have_link user.name, href: user_path(user) }
    end
  end
end
