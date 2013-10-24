Directory::Application.routes.draw do

  match 'requires_browser_update' => 'settings#requires_browser_update'

  unauthenticated :person do
    devise_scope :person do
      get "/" => "devise/sessions#new"
    end
  end

  authenticated :person do
    root :to => 'people#welcome'
  end

  devise_for :people
  resources  :people do
    member do
      get 'dashboard', 'change_password'
      post 'update_password'
      put 'update_password'
    end

    collection do
      get 'paginate', 'search', 'title_search', 'nationality_search'
    end

    resources :activities, :controller => 'people/activities'
    resources :histories, :controller => 'people/histories'

    # TODO
    # I think this is a bad idea (see http://weblog.jamisbuck.org/2007/2/5/nesting-resources),
    # but because we want namescoped controllers, we are kinda forced to do it.
    # IMHO a better solution would be to remove the namescoped controllers to have smth much more flat.
    resources :affairs, :controller => 'people/affairs' do
      collection do
        get 'search'
      end

      resources :invoices, :controller => 'people/affairs/invoices' do
        collection do
          get 'search'
        end
      end

      resources :receipts, :controller => 'people/affairs/receipts'

      resources :subscriptions, :controller => 'people/affairs/subscriptions' do
        collection do
          delete 'destroy' #spine posts on this by default
        end
      end
    end

    resources :comments, :controller => 'people/comments'

    resources :communication_languages, :controller => 'people/communication_languages', :only => :index do
      collection do
        put 'update' # spine posts on this by default
      end
    end

    resources :employment_contracts, :controller => 'people/employment_contracts'

    resources :private_tags, :controller => 'people/private_tags', :only => :index do
      collection do
        put 'update' # spine posts on this by default
      end
    end

    resources :public_tags, :controller => 'people/public_tags', :only => :index do
      collection do
        put 'update' # spine posts on this by default
      end
    end

    resources :roles, :controller => 'people/roles', :only => :index do
      collection do
        put 'update' # spine posts on this by default
      end
    end

    resources :salaries, :controller => 'people/salaries/salaries' do
      member do
        put 'update_items', 'update_tax_data'
      end

      resources :items, :controller => 'people/salaries/items', :only => [ :index ] do
        member do
          get 'compute_value_for_next_salaries', 'compute_value_for_this_salary'
        end
      end

      resources :tax_data, :controller => 'people/salaries/tax_data', :only => [ :index ] do
        member do
          put 'reset'
          get 'compute_value_for_next_salaries', 'compute_value_for_this_salary'
        end
      end
    end

    resources :tasks, :controller => 'people/tasks'
    resources :translation_aptitudes, :controller => 'people/translation_aptitudes'
  end

  match 'salaries' => 'salaries#index'
  namespace :salaries do
    resources :salaries, :only => [:index, :update, :destroy] do
      member do
        post 'copy_reference'
      end
      collection do
        get 'pending', 'export', 'export_accounting', 'export_ocas', 'export_certificates', 'available_years'
      end
    end

    resources :taxes do
      member do
        post :import_data
      end
      collection do
        get :models
      end
    end
  end

  match 'directory' => 'directory#index', :via => [:get, :post]
  match 'directory/mailchimp' => 'directory#mailchimp', :via => :post
  namespace :directory do
    resources :query_presets
  end

  match 'admin' => 'admin#index'
  match 'admin/confirm_people' => 'admin#confirm_people', :via => :post
  match 'admin/import_people' => 'admin#import_people', :via => :post
  namespace :admin do
    resources :affairs do
      collection do
        get 'search'
      end
    end

    resources :bank_import_histories, :only => :index do
      collection do
        post 'confirm', 'import'
        get 'export'
      end
    end

    resources :invoices do
      collection do
        get 'export'
      end
    end

    resources :private_tags do
      member do
        post 'add_members', 'remove_all_members'
      end
      collection do
        get 'search'
      end
    end

    resources :public_tags do
      member do
        post 'add_members', 'remove_all_members'
      end
      collection do
        get 'search'
      end
    end

    resources :receipts do
      collection do
        get 'export', 'means_of_payments'
      end
    end

    resources :subscriptions do
      member do
        # POST on show is required for the PDF generation from the search engine
        post 'add_members', 'transfer_overpaid_value', 'show'
        delete 'remove_members'
      end
      collection do
        put 'tag_tool'
        get 'search'
      end
    end
  end

  resources :background_tasks, :only => [:index, :destroy]

  resources :settings, :only => :index do
    collection do
      get 'requires_browser_update'
    end
  end
  namespace :settings do
    resources :application_settings

    resources :invoice_templates do
      collection do
        get 'placeholders'
      end
    end

    resources :salary_templates do
      collection do
        get 'placeholders'
      end
    end

    resources :jobs do
      collection do
        get 'search'
      end
    end

    resources :languages

    resources :ldap_attributes do
      collection do
        post 'synchronize'
      end
    end

    resources :locations do
      collection do
        get 'search'
      end
    end

    resources :permissions, :only => :index

    resources :roles do
      resources :permissions, :controller => 'roles/permissions'
    end

    resources :search_attributes do
      collection do
        get 'searchable'
        post 'synchronize'
      end
    end
  end

  resources :permissions, :only => :index, :controller => 'people/permissions'

end
