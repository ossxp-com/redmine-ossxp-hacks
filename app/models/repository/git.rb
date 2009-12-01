# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
# Copyright (C) 2007  Patrick Aljord patcito@ŋmail.com
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

require 'redmine/scm/adapters/git_adapter'

class ChangesAdapter < Array
  def find(f, attributes={})
    self
  end
end

class ChangeAdapter
  attr_accessor :changeset, :revision, :action, :path, :from_path, :from_revision

  def initialize(changeset, revision, change)
    self.changeset = changeset
    self.revision = revision 
    self.action = change[:action]
    self.path = change[:path]
    self.from_path = change[:from_path]
    self.from_revision = change[:from_revision]
  end

end

class ChangesetAdapter

  attr_accessor :repository, :revision, :scmid, :name, :committer, :committed_on, :comments, :previous, :next
  def initialize(repository, revision, previous=nil, thenext=nil)
    self.repository = repository
    self.revision = revision.identifier 
    self.scmid = revision.scmid
    self.name = revision.name
    self.committer = revision.author
    self.committed_on = revision.time
    self.comments = revision.message
    self.previous = previous
    self.next = thenext
    @user = self.repository.find_committer_user(self.committer)
    @changes = ChangesAdapter.new(revision.paths.collect do |change|
      ChangeAdapter.new(self, revision.identifier, change)
    end)
    @unauth_path = []
  end

  def author
    @user || self.committer.to_s.split('<').first
  end

  def project
    self.repository.project
  end

  def issues
    []
  end

  def changes
    @changes
  end

  def unauth_path=(unauth_path)
    @unauth_path = unauth_path
  end

  def unauth_path
    @unauth_path
  end

end


class Repository::Git < Repository
  attr_protected :root_url
  validates_presence_of :url

  def scm_adapter
    Redmine::Scm::Adapters::GitAdapter
  end
  
  def self.scm_name
    'Git'
  end

  def changesets_find_by_revision(rev, options={})
    #changeset = changesets.find_by_revision(rev)
    changeset = nil
    if changeset.nil?
      #revision = scm.get_rev(rev, '')
      c = nil
      changesets=scm.revisions('', rev, options[:branch], :limit => 2, :reverse => true).collect do |revision|
        c = ChangesetAdapter.new(self, revision, c, nil)
        c
      end
      changeset = changesets.last unless changesets.nil?
      #changeset.revision=rev
    end
    changeset
  end

  def changesets_find_git(path, rev, f, options={})
    changesets=nil
    if changesets.nil?
      c=nil
      #rev='--all' if rev.nil?
      rev='HEAD' if rev.nil?
      offset = options[:offset] ? options[:offset] : 0
      limit = options[:limit] ? options[:limit] : 1
      limit += offset
      
      changesets=scm.revisions(path, rev, nil, :limit => limit).collect do |revision|
        cnew=ChangesetAdapter.new(self, revision, c, nil)
        c.next=cnew if c
        c=cnew
        c
      end
    end
    changesets[offset, limit]
  end
  
  def changesets_find(path, rev, f, options={})
    if (path.nil? || path == '' ) && (rev.nil? || rev == '')
      super(path, rev, f, options)
    else
      changesets_find_git(path, rev, f, options)
    end
  end
  
  def changesets_count(path, rev, f)
    # FIXME: Optimize via new scm.count_revs function
    if (path.nil? || path == '' ) && (rev.nil? || rev == '')
      super(path, rev, f)
    else
      scm.revisions(path, rev, nil).count
    end
  end

  def changesets_for_path(path,options={})
    changesets_find_git(path, options[:branch], :all, options)
  end

  def fetch_changesets
    scm_info = scm.info
    if scm_info
      # latest revision found in database
      db_revision = latest_changeset ? latest_changeset.revision : nil
      # latest revision in the repository
      scm_revision = scm_info.lastrev.scmid

      unless changesets.find_by_scmid(scm_revision)
        # Get all commit heads until our stored revision
        scm.revisions('', '--all', db_revision ? ('^' + db_revision) : nil, :reverse => true) do |revision|
          if changesets.find_by_scmid(revision.scmid.to_s).nil?
            transaction do
              changeset = Changeset.create!(:repository => self,
                                           :revision => revision.identifier,
                                           :scmid => revision.scmid,
                                           :committer => revision.author, 
                                           :committed_on => revision.time,
                                           :comments => revision.message)
              
              revision.paths.each do |change|
                Change.create!(:changeset => changeset,
                              :action => change[:action],
                              :path => change[:path],
                              :from_path => change[:from_path],
                              :from_revision => change[:from_revision])
              end
            end
          end
        end
      end
    end
  end
end
