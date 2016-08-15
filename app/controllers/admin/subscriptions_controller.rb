=begin
  CIRCL Directory
  Copyright (C) 2011 Complex IT sàrl

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as
  published by the Free Software Foundation, either version 3 of the
  License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

class Admin::SubscriptionsController < ApplicationController

  layout false

  load_and_authorize_resource

  monitor_changes :@subscription

  def index
    respond_to do |format|
      format.json { render json: SubscriptionsDatatable.new(view_context) }
    end
  end

  def show
    query = JSON.parse params[:query]
    query ||= {}
    query.symbolize_keys!
    # Enforce search string, keep attributes order.
    query[:search_string] = "subscriptions.id:#{@subscription_id}"

    respond_to do |format|
      format.json { render json: @subscription }
      format.pdf do
        if @subscription.pdf_up_to_date?(query) and File.exist?(@subscription.pdf.path)
          send_data File.read(@subscription.pdf.path),
            filename: "subscription_#{params[:id]}.pdf",
            type: 'application/pdf'
        else
          if params[:query]
            Resque.enqueue(Subscriptions::PreparePdfsAndEmail,
              subscription_id: @subscription.id,
              query: query,
              user_id: current_person.id,
              current_locale: I18n.locale)
            flash[:notice] = I18n.t('admin.notices.pdf_will_be_sent', email: current_person.email)
          else
            flash[:error] = I18n.t('directory.errors.query_invalid')
          end
          redirect_to admin_path(anchor: 'affairs')
        end
      end
    end
  end

  def add_members
    respond_to do |format|
      query = JSON.parse params[:query]
      query.symbolize_keys!

      if query[:search_string].blank?
        format.json { render json: { search_string: [I18n.t('activerecord.errors.messages.blank')] }, status: :unprocessable_entity }
        format.html {
          flash[:alert] = I18n.t("directory.errors.query_empty")
          redirect_to admin_path(anchor: 'affairs')
        }
      else
        Resque.enqueue(Subscriptions::AddPeopleAndEmail,
          query: query,
          subscription_id: @subscription.id,
          user_id: current_person.id,
          parent_subscription_id: nil,
          status: nil)

        flash[:notice] = I18n.t('admin.notices.add_members_email_will_be_sent', email: current_person.email)
        format.json { render json: {} }
        format.html do
          # TODO improve report
          flash[:notice] = I18n.t("subscription.notices.members_added")
          redirect_to admin_path(anchor: 'affairs')
        end
      end
    end
  end

  def remove_members
    respond_to do |format|
      # ensure there is no receipts
      if @subscription.receipts.count > 0
        format.json { render json: { subscription_id: [I18n.t('subscription.errors.cannot_remove_members_if_there_is_receipts')] }, status: :unprocessable_entity }
      else
        @subscription.destroy_affairs # This will destroy dependent stuff
        format.json { render json: {} }
      end
    end
  end

  def transfer_overpaid_value
    errors = {}

    # TODO Move this to a background task
    if @subscription.values.size <= 1 and @subscription.values.try(:first).try(:value) == 0
      errors[:subscription_id] = [ I18n.t('subscription.errors.cannot_transfer_overpaid_value_if_subscription_value_is_zero') ]
    elsif ! Subscription.exists?(params[:transfer_to_subscription_id])
      errors[:transfer_to_subscription_id] = [ I18n.t('activerecord.errors.messages.blank') ]
    else
      transfer_to = Subscription.find(params[:transfer_to_subscription_id])

      Subscription.transaction do
        @subscription.affairs.each do |affair|
          new_affair = Affair.new title: transfer_to.title,
            owner_id: affair.owner_id,
            created_at: affair.created_at,
            updated_at: affair.updated_at

          # Affair requires to be saved before adding subscriptions
          new_affair.save!
          new_affair.subscriptions = [ transfer_to ]

          affair.invoices.each do |invoice|
            # Skip invoices that are not overpaid
            next unless invoice.overpaid?

            # We found one, create the new affair if needed
            if new_affair.new_record? && new_affair.save == false
              errors = new_affair.errors
              raise ActiveRecord::Rollback
            end

            # Create the new invoice
            overpaid_value = invoice.overpaid_value
            new_invoice = Invoice.new value: overpaid_value,
              title: new_affair.title,
              affair_id: new_affair.id,
              invoice_template_id: transfer_to.invoice_template_for(invoice.owner),
              created_at: invoice.created_at,
              updated_at: invoice.updated_at
            unless new_invoice.save
              errors = new_invoice.errors
              raise ActiveRecord::Rollback
            end

            # TODO figure out which receipt introduced the overpay and
            # then create the receipts that follow too, updating each of them
            # For now, loop over the receipts and decrease their value until there's no overpayment
            while overpaid_value > 0
              receipt = invoice.receipts.order(:created_at).last
              break unless receipt

              if receipt.value > overpaid_value.to_money
                receipt.value -= overpaid_value.to_money
                unless receipt.save
                  errors = receipt.errors
                  raise ActiveRecord::Rollback
                end
                overpaid_value = 0.to_money
              else
                overpaid_value -= receipt.value
                receipt.destroy
              end
            end

            # Create the new receipt
            new_receipt = Receipt.new value: new_invoice.value,
              invoice_id: new_invoice.id,
              value_date: receipt.value_date,
              means_of_payment: receipt.means_of_payment,
              created_at: receipt.created_at,
              updated_at: receipt.updated_at
            unless new_receipt.save
              errors = new_receipt.errors
              raise ActiveRecord::Rollback
            end
          end
        end
      end
    end

    respond_to do |format|
      if errors.empty?
        format.json { render json: @subscription }
      else
        format.json { render json: errors, status: :unprocessable_entity }
      end
    end
  end

  def create
    succeed = false

    Subscription.transaction do
      # Only allow reminders to be the child of a subscription
      @subscription.parent_id = nil unless params[:status] == 'reminder'

      # raise the error and rollback transaction if validation fails
      raise ActiveRecord::Rollback unless @subscription.save

      # append values
      params[:values].each do |v|
        sv = @subscription.values.new(value: v[:value],
          position: v[:position],
          private_tag_id: v[:private_tag_id],
          invoice_template_id: v[:invoice_template_id])
        unless sv.save
          sv.errors.messages.each do |k,v|
            @subscription.errors.add(("values[][" + k.to_s + "]").to_sym, v.join(", "))
          end
          raise ActiveRecord::Rollback
        end
      end

      if ! params[:parent_id].blank?
        case params[:status]
        when 'reminder'
          people_ids = @subscription.parents.map{ |p| p.get_people_from_affairs_status(:open).map(&:id) }.flatten
        when 'renewal'
          people_ids = Subscription.find(params[:parent_id]).get_people_from_affairs_status(:paid).map(&:id)
        end

        unless people_ids.empty?
          search_string = "id:(#{people_ids.join(' ')})"

          Resque.enqueue(Subscriptions::AddPeopleAndEmail,
            subscription_id: @subscription.id,
            query: { search_string: search_string },
            user_id: current_person.id,
            parent_subscription_id: params[:parent_id],
            status: params[:status])
        end

      end
      succeed = true
    end

    respond_to do |format|
      if succeed
        format.json { render json: @subscription }
      else
        format.json { render json: @subscription.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render json: @subscription }
    end
  end

  def update
    succeed = false

    # Update the subscription
    Subscription.transaction do
      # remove parent if not sent
      params[:subscription][:parent_id] = nil unless params[:subscription][:parent_id]
      # raise the error and rollback transaction if validation fails
      raise ActiveRecord::Rollback unless @subscription.update_attributes(params[:subscription])

      # Only keep values that are returned
      surplus_values = @subscription.values.map(&:id) - params[:values].map{|v| v[:id].to_i}
      SubscriptionValue.destroy surplus_values

      # and append or update values
      params[:values].each do |v|
        if @subscription.values.exists?(v[:id])
          sv = @subscription.values.find(v[:id])
          sv.value               = v[:value]
          sv.position            = v[:position]
          sv.private_tag_id      = v[:private_tag_id]
          sv.invoice_template_id = v[:invoice_template_id]
        else
          sv = @subscription.values.new(value: v[:value],
            position: v[:position],
            private_tag_id: v[:private_tag_id],
            invoice_template_id: v[:invoice_template_id])
        end

        unless sv.save
          sv.errors.messages.each do |k,v|
            @subscription.errors.add(("values[][" + k.to_s + "]").to_sym, v.join(", "))
          end
          raise ActiveRecord::Rollback
        end
      end

      # TODO ideally this should be in after_save callback in Subscription model. Only current_person (email) prevent it.
      Resque.enqueue(Subscriptions::UpdateInvoicesAndEmail,
        subscription_id: @subscription.id,
        user_id: current_person.id)

      succeed = true
    end

    respond_to do |format|
      if succeed
        format.json { render json: @subscription }
      else
        format.json { render json: @subscription.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @subscription.destroy
        format.json { render json: {} }
      else
        format.json { render json: @subscription.errors, status: :unprocessable_entity }
      end
    end
  end

  def search
    if params[:term].blank?
      result = []
    else
      param = params[:term].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      if param.is_i?
        result = @subscriptions.where("subscriptions.id = ? OR subscriptions.parent_id = ?", param, param)
      else
        result = @subscriptions.where("subscriptions.title ~* ?", param)
      end
    end

    respond_to do |format|
      format.json { render json: result.map{|t| {id: t.id, label: t.title}}}
    end
  end

  def count
    respond_to do |format|
      format.json { render json: {count: Subscription.count} }
    end
  end

  def tag_tool
    # Pseudo validation
    @errors = {}
    if validate_date_format(params[:date])
      date = Date.parse(params[:date])
    else
      @errors[:date] = [I18n.t("subscription.views.tag_tool.wrong_date")]
    end

    if params[:private_tag_id].blank?
      @errors[:private_tag_id] = [I18n.t("subscription.views.tag_tool.tag_name_missing")]
    else
      tag = PrivateTag.find params[:private_tag_id]
    end

    if @errors.empty?
      begin
        # Find members of a subscription
        if params[:subscription_member]
          people_arel = Person.joins(:subscriptions)
            .where("? BETWEEN interval_starts_on AND interval_ends_on", date)
        else
          people_arel = Person.joins(:subscriptions)
            .where("? NOT BETWEEN interval_starts_on AND interval_ends_on", date)
        end

        # And extract paying member or extract not paying members
        if params[:subscription_member] and params[:subscription_paid]
          Person.transaction do
            mask = Affair.statuses_value_for(:paid)
            people_arel
              .where("(affairs.status::bit(16) & ?::bit(16))::int = ?", mask, mask).uniq
              .each do |p|
                p.private_tags << tag
            end
          end
        else
          if params[:subscription_member]
            Person.transaction do
              mask = Affair.statuses_value_for(:open)
              people_arel
                .where("(affairs.status::bit(16) & ?::bit(16))::int = ?", mask, mask).uniq
                .each do |p|
                  p.private_tags << tag
              end
            end
          elsif params[:subscription_paid]
            Person.transaction do
              mask = Affair.statuses_value_for(:paid)
              people_arel
                .where("(affairs.status::bit(16) & ?::bit(16))::int = ?", mask, mask).uniq
                .each do |p|
                  p.private_tags << tag
              end
            end
          end
        end

        success = true

      rescue Exception => e

        @errors[:unprocessable] = [I18n.t("subscription.views.tag_tool.unprocessable_request") + " " + e.inspect]

      end
    end

    respond_to do |format|
      if success
        format.json { render json: {} }
      else
        format.json { render json: @errors , status: :unprocessable_entity }
      end
    end
  end

  def merge
    @errors = {}
    if params[:id].blank?
      @errors[:id] = [I18n.t("subscription.views.merge.source_subscription_id_missing")]
    end

    if params[:transfer_to_subscription_id].blank?
      @errors[:transfer_to_subscription_id] = [I18n.t("subscription.views.merge.destination_subscription_id_missing")]
    end


    respond_to do |format|
      if @errors.size > 0
        format.json { render json: @errors , status: :unprocessable_entity }
      else
        Resque.enqueue(Subscriptions::MergeSubscriptions,
          source_subscription_id: params[:id],
          destination_subscription_id: params[:transfer_to_subscription_id],
          user_id: current_person.id)

        format.json { render json: {} }
      end
    end
  end

  #
  # Generate PDF front page, a summary to keep sorting, date and references information within the PDF itself
  # @param subscription [Subscription] object it's all about
  #
  # @return [String] html page
  def pdf_front_page(subscription, query)

    @subscription = subscription
    @query = query
    render_to_string("pdf_front_page")

  end

end
