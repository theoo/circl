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
      get 'change_password', 'map'
      post 'update_password'
      put 'update_password'
    end

    collection do
      get 'paginate', 'search', 'title_search', 'nationality_search'
    end

    resources :dashboard, :controller => 'people/dashboard', :only => :index do
      collection do
        get 'comments', 'activities', 'last_people_added', 'open_invoices', 'current_affairs',
          'open_salaries'
      end
    end

    resources :activities, :controller => 'people/activities'
    resources :histories, :controller => 'people/histories'

    resources :affairs, :controller => 'people/affairs' do
      collection do
        get 'search', 'affairs', 'invoices', 'receipts'
      end

      resources :extras, :controller => 'people/affairs/extras' do
        collection do
          get 'count'
        end
      end

      resources :invoices, :controller => 'people/affairs/invoices' do
        collection do
          get 'search'
        end
      end

      resources :products, :controller => 'people/affairs/products' do
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
      resources :tasks, :controller => 'people/affairs/tasks'
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
    resources :salaries, :except => [:edit] do
      member do
        post 'copy_reference'
      end
      collection do
        get 'pending', 'export', 'export_accounting', 'export_ocas', 'export_certificates', 'available_years'
      end
    end

    resources :taxes do
      member do
        post 'import_data'
      end
      collection do
        get 'models', 'count'
      end
    end
  end

  match 'directory' => 'directory#index', :via => [:get, :post]
  match 'directory/mailchimp' => 'directory#mailchimp', :via => :post
  match 'directory/map' => 'directory#map', :via => :get
  match 'directory/confirm_people' => 'directory#confirm_people', :via => :post
  match 'directory/import_people' => 'directory#import_people', :via => :post
  namespace :directory do
    resources :query_presets
  end

  match 'admin' => 'admin#index'
  namespace :admin do
    resources :affairs do
      collection do
        get 'search', 'available_statuses'
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
        get 'export', 'available_statuses'
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
        get 'export', 'means_of_payments', 'documents'
        post 'documents'
      end
    end

    resources :subscriptions do
      member do
        # POST on show is required for the PDF generation from the search engine
        post 'add_members', 'transfer_overpaid_value', 'show', 'merge'
        delete 'remove_members'
      end
      collection do
        put 'tag_tool'
        get 'search', 'count'
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

    resources :currencies do
      collection do
        get 'search'
      end
    end

    resources :currency_rates do
      collection do
        get 'exchange'
      end
    end

    resources :generic_templates do
      collection do
        get 'count'
      end
      member do
        post 'upload_odt'
      end
    end

    resources :invoice_templates do
      collection do
        get 'placeholders', 'count'
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

    resources :products do
      collection do
        get 'search', 'count'
      end
      member do
        get 'programs'
      end
    end

    resources :product_programs do
      collection do
        get 'program_groups', 'program_group_search', 'search', 'count'
      end
    end

    resources :roles do
      resources :permissions, :controller => 'roles/permissions'
    end

    resources :search_attributes do
      collection do
        get 'searchable'
        post 'synchronize'
      end
    end

    # resources :tasks
    resources :task_types do
      collection do
        get 'everything'
      end
    end
    resources :task_rates do
      collection do
        get 'everything'
      end
    end

  end

  resources :permissions, :only => :index, :controller => 'people/permissions'

end
