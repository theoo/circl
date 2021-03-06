module ControllerExtensions
  module Affairs
    def search
      if params[:term].blank?
        result = []
      else
        if params[:term].is_i?
          result = @affairs.where("affairs.id = ?", params[:term])
        else
          param = params[:term].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
          result = @affairs.where("affairs.title ~* ? OR affairs.alias_name ~* ?", param, param)
        end
      end

      result = result.limit(10)

      respond_to do |format|
        format.json do
          render json: result.map{|t|
            desc = " "
            if t.estimate
              desc += "<i>" + I18n.t("affair.views.estimate") + "</i> - "
            end
            desc += t.try(:owner).try(:name).to_s
            desc += "<br />" + t.description.exerpt unless t.description.blank?

            { id: t.id,
              title: t.id.to_s,
              label: t.title,
              desc: desc,
              owner_id: t.owner_id,
              owner_name: t.owner.try(:name) }
          }
        end
      end
    end
  end
end