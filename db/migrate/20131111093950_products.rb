class Products < ActiveRecord::Migration
  def up
    # PRODUCTS
    create_table :products do |t|
      t.integer :provider_id
      t.integer :after_sale_id

      t.string  :key, :null => false
      t.string  :title
      t.string  :category
      t.text    :description
      t.boolean :has_accessories, :null => false, :default => false
      t.boolean :archive, :null => false, :default => false

      t.timestamps
    end
    add_index :products, :provider_id
    add_index :products, :after_sale_id
    add_index :products, :key
    add_index :products, :title
    add_index :products, :category
    add_index :products, :has_accessories

    # VARIANTS
    create_table :product_variants do |t|
      t.integer :product_id, :null => false

      t.string  :program_group, :null => false
      t.string  :title

      t.integer :buying_price_in_cents
      t.string  :buying_price_currency, :null => false, :default => 'CHF'
      t.integer :selling_price_in_cents, :null => false
      t.string  :selling_price_currency, :default => 'CHF'
      # http://en.wikipedia.org/wiki/Electronic_Waste_Recycling_Fee for switzerland
      t.integer :art_in_cents
      t.string  :art_currency, :default => 'CHF'

      t.timestamps
    end
    add_index :product_variants, :product_id
    add_index :product_variants, :program_group
    add_index :product_variants, :buying_price_in_cents
    add_index :product_variants, :selling_price_in_cents
    add_index :product_variants, :art_in_cents

    # PROGRAMS
    create_table :product_programs do |t|
      t.string  :key, :null => false
      t.string  :program_group, :null => false
      t.string  :title
      t.text    :description
      t.boolean :archive, :null => false, :default => false

      t.timestamps
    end
    add_index :product_programs, :key
    add_index :product_programs, :program_group
    add_index :product_programs, :title
    add_index :product_programs, :archive

    # PRODUCT LISTS
    create_table :affairs_products_programs do |t|
      t.integer :parent_id
      t.integer :affair_id
      t.integer :product_id
      t.integer :program_id
      t.integer :position
      t.float   :quantity

      t.timestamps
    end
    add_index :affairs_products_programs, [:affair_id, :product_id, :position], :uniq => true, :name => "affairs_products_programs_unique_position"
    add_index :affairs_products_programs, :parent_id
    add_index :affairs_products_programs, :affair_id
    add_index :affairs_products_programs, :program_id
    add_index :affairs_products_programs, :product_id
  end

  def down
    drop_table :products
    drop_table :product_variants
    drop_table :product_programs
    drop_table :affairs_products_programs
  end
end
