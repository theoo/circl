module VatConcern

  extend ActiveSupport::Concern

  # Takes a value taxes included
  def reverse_vat(val)
    val / ( 1 + (ApplicationSetting.value("service_vat_rate").to_f / 100) )
  end

end