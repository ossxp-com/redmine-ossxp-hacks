class AddScmAuthz < ActiveRecord::Migration
  def self.up
    add_column :repositories, :authz_file, :string, :limit => 255, :default => ""
  end

  def self.down
    remove_column :repositories, :authz_file
  end
end
