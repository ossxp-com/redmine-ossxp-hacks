class AddScmAuthz < ActiveRecord::Migration
  def self.up
    add_column :repositories, :authz_file, :string, :limit => 255, :default => ""
    add_column :repositories, :authz_module_name, :string, :limit => 30, :default => ""
  end

  def self.down
    remove_column :repositories, :authz_file
    remove_column :repositories, :authz_module_name
  end
end
