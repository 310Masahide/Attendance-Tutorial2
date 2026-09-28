module StatusPresentable
  extend ActiveSupport::Concern

  included do
    enum status: { unset: 0, pending: 1, approved: 2, rejected: 3 }
    scope :awaiting_decision, -> { pending }
  end

  def status_label
    I18n.t("activerecord.attributes.#{self.class.model_name.i18n_key}.statuses.#{status}")
  end

  def decided?
    approved? || rejected?
  end

  class_methods do
    def status_options
      statuses.keys.map { |status_name| [I18n.t("activerecord.attributes.#{model_name.i18n_key}.statuses.#{status_name}"), status_name] }
    end
  end
end
