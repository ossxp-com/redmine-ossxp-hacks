class AddDefaultFixedVersion < ActiveRecord::Migration
  def self.up
    add_column :projects, :default_fixed_version, :integer
  end

  def self.down
    remove_column :projects, :default_fixed_version
  end
end 
