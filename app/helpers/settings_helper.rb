# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

module SettingsHelper
  def administration_settings_tabs
    tabs = [{:name => 'general', :partial => 'settings/general', :label => :label_general},
            {:name => 'authentication', :partial => 'settings/authentication', :label => :label_authentication},
            {:name => 'projects', :partial => 'settings/projects', :label => :label_project_plural},
            {:name => 'issues', :partial => 'settings/issues', :label => :label_issue_tracking},
            {:name => 'notifications', :partial => 'settings/notifications', :label => l(:field_mail_notification)},
            {:name => 'mail_handler', :partial => 'settings/mail_handler', :label => l(:label_incoming_emails)},
            {:name => 'repositories', :partial => 'settings/repositories', :label => :label_repository_plural}
            ]
  end
  def sso_method_message
    filename = AuthSource.get_fallback_file_name
    fallback = AuthSource.sso_get_fallback
    message = l(:text_sso_method_message, filename)+"\n"
    case
    when fallback == 0
      message += l(:text_sso_fallback_disable, filename)
    when fallback == 1
      message += l(:text_sso_fallback_cosign_v2, filename)
    when fallback == 2
      message += l(:text_sso_fallback_cosign_v3, filename)
    end
  end
  def real_sso_method
    AuthSource.real_sso_method
  end
end
