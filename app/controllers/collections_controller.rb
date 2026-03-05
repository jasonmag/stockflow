class CollectionsController < ApplicationController
  def index
    @collections = current_business.collections.order(collected_on: :desc)
  end
end
