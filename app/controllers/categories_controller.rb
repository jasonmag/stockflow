class CategoriesController < ApplicationController
  before_action :set_category, only: %i[edit update destroy]

  def index
    @categories = current_business.categories.order(:name)
    @category = current_business.categories.new
  end

  def create
    @category = current_business.categories.new(category_params)
    if @category.save
      redirect_to categories_path, notice: "Category created."
    else
      @categories = current_business.categories.order(:name)
      render :index, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @category.update(category_params)
      redirect_to categories_path, notice: "Category updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @category.destroy
    redirect_to categories_path, notice: "Category deleted."
  end

  private
    def set_category
      @category = current_business.categories.find(params[:id])
    end

    def category_params
      params.require(:category).permit(:name)
    end
end
