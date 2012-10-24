class StaticPagesController < ApplicationController
  def home
    if signed_in?
      @micropost = current_user.microposts.build
      @feed_items = current_user.proto_feed.paginate page: params[:page]
    end
  end

  def help
  end

  def about
  end

  def contact
  end
end
