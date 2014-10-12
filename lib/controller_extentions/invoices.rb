module ControllerExtentions
  module Invoices
    def search
      if params[:term].blank?
        result = []
      else
        if params[:term].is_i?
          result = @invoices.where("invoices.id = ?", params[:term])
        else
          param = params[:term].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
          result = @invoices.where("invoices.title ~* ?", param)
        end
      end

      result = result.limit(10)

      respond_to do |format|
        format.json do
          render json: result.map{|t|
            desc = t.try(:owner).try(:name)
            desc += "<br />" + t.description.exerpt unless t.description.blank?

            { id: t.id,
              title: t.id.to_s,
              label: t.title,
              desc: desc }}
        end
      end
    end
  end
end