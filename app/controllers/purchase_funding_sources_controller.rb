class PurchaseFundingSourcesController < ApplicationController
  require "uri"
  require "rack/utils"

  before_action :require_owner!
  before_action :set_purchase_funding_source, only: %i[edit update]

  def index
    @purchase_funding_sources = current_business.purchase_funding_sources.order(:name)
  end

  def new
    @purchase_funding_source = current_business.purchase_funding_sources.new
    @cancel_path = safe_return_to || purchase_funding_sources_path
  end

  def edit; end

  def create
    @purchase_funding_source = current_business.purchase_funding_sources.new(purchase_funding_source_params)
    @cancel_path = safe_return_to || purchase_funding_sources_path
    if @purchase_funding_source.save
      redirect_to purchase_funding_source_redirect_target, notice: "Funding source created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @purchase_funding_source.update(purchase_funding_source_params)
      redirect_to purchase_funding_sources_path, notice: "Funding source updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_purchase_funding_source
      @purchase_funding_source = current_business.purchase_funding_sources.find(params[:id])
    end

    def purchase_funding_source_params
      params.require(:purchase_funding_source).permit(:name, :source_type)
    end

    def purchase_funding_source_redirect_target
      return purchase_funding_sources_path unless safe_return_to.present?

      uri = URI.parse(safe_return_to)
      query = Rack::Utils.parse_nested_query(uri.query).merge("funding_source" => @purchase_funding_source.name)
      uri.query = query.to_query.presence
      uri.to_s
    end

    def safe_return_to
      @safe_return_to ||= url_from(params[:return_to])
    end
end
