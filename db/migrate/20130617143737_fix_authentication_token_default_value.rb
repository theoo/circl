class FixAuthenticationTokenDefaultValue < ActiveRecord::Migration
  def up
    change_column_default :people, :authentication_token, nil
  end

  def down
  end
end
