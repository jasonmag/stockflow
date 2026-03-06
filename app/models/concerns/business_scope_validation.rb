module BusinessScopeValidation
  extend ActiveSupport::Concern

  included do
    validate :validate_business_scoped_associations
  end

  class_methods do
    def validates_same_business_of(*association_names)
      @business_scoped_associations ||= []
      @business_scoped_associations.concat(association_names)
    end

    def business_scoped_associations
      @business_scoped_associations || []
    end
  end

  private
    def validate_business_scoped_associations
      return unless respond_to?(:business_id)
      return if business_id.blank?

      self.class.business_scoped_associations.each do |association_name|
        record = public_send(association_name)
        next if record.blank? || !record.respond_to?(:business_id)
        next if record.business_id == business_id

        errors.add(association_name, "must belong to the current business")
      end
    end
end
