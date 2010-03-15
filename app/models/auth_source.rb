# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class AuthSource < ActiveRecord::Base
  has_many :users
  
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 60

  def authenticate(login, password, sso_loggedin=false)
  end
  
  def test_connection
  end
  
  def auth_method_name
    "Abstract"
  end

  # Try to authenticate a user not yet registered against available sources
  def self.authenticate(login, password, sso_loggedin=false)
    AuthSource.find(:all, :conditions => ["onthefly_register=?", true]).each do |source|
      begin
        logger.debug "Authenticating '#{login}' against '#{source.name}'" if logger && logger.debug?
        attrs = source.authenticate(login, password, sso_loggedin)
      rescue => e
        logger.error "Error during authentication: #{e.message}"
        attrs = nil
      end
      return attrs if attrs
    end
    return nil
  end

  # Get fallback file name
  def self.get_fallback_file_name
    "#{RAILS_ROOT}/config/FALLBACK"
  end

  # Get fallback auth method
  def self.sso_get_fallback
    fallback_file = self.get_fallback_file_name
    return -1 if not File.exists? fallback_file
    fallback = 0
    line = ""
    File.open(fallback_file) do |file|
      line = file.gets
      line.strip!.downcase! if line
    end
    case
    when line == "cosign2"
      fallback = 1
    when line == "cosign3"
      fallback = 2
    end
    return fallback
  end

  # Get real sso login method
  def self.real_sso_method
    return 0 if AuthSource.count <= 0
    fallback = self.sso_get_fallback
    return fallback == -1 ? Setting.sso_method.to_i : fallback
  end
end
