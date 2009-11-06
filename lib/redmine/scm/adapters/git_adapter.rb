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

require 'redmine/scm/adapters/abstract_adapter'

module Redmine
  module Scm
    module Adapters    
      class GitAdapter < AbstractAdapter
        
        # Git executable name
        GIT_BIN = "git"
        
        def check_revision(rev, many=true)
          rev='' if rev.nil?
          cmd="#{GIT_BIN} --git-dir #{target('')} rev-parse #{shell_quote rev}"
          newrev='HEAD' unless many
          newrev='--all' if many
          shellout(cmd) do |io|
            io.each_line do |line|
              if line =~ /^([0-9a-f]{40})$/
                newrev=$1 unless many
                newrev=rev if many
                break
              end
            end
          end
          newrev || 'HEAD'
        end

        ## Refs may have / in it. for example, topgit always use branch name such as t/branch/name
        ## by Jiang Xin <jiangxin AT ossxp.com>
        def parse_refs(treepath)
            if treepath =~ /^refs\/([^\/]+)\/([^\/]+)(\/.*)?$/
                type = $1
                tree = $2
                path = $3 || ''
                if path
                    path=path[1..-1]
                end
                cmd="#{GIT_BIN} --git-dir #{target('')} rev-parse #{type}/#{tree} >/dev/null 2>&1"
                system(cmd)
                while $?.exitstatus != 0 and path
                    tree_extra, path = path.split('/',2)
                    tree = "#{tree}/#{tree_extra}"
                    cmd="#{GIT_BIN} --git-dir #{target('')} rev-parse #{type}/#{tree} >/dev/null 2>&1"
                    system(cmd)
                end
                if $?.exitstatus == 0
                    return type, tree, path
                end
            end
            return '', '', treepath
        end

        # Get the revision of a particuliar file
        def get_rev (rev,treepath)
          type_tree ||= '' 
	      path ||= '' 
          type, tree, node_path = parse_refs(treepath)
          if type and tree
	          type_tree = "#{type}/#{tree}"
              path = node_path
          end
	    if rev != 'latest' && !rev.nil?
	      #cmd="#{GIT_BIN} --git-dir #{target('')} show --raw --date=iso --pretty=fuller  #{shell_quote rev} #{shell_quote type_tree} -- #{shell_quote path}" 
	      cmd="#{GIT_BIN} --git-dir #{target('')} show --raw --date=iso --pretty=fuller -1 #{shell_quote rev}" 
          if path
              cmd += " -- #{shell_quote path}"
          end
	    else
	      #@branch ||= shellout("#{GIT_BIN} --git-dir #{target('')} branch") { |io| io.grep(/\*/)[0].strip.match(/\* (.*)/)[1] }
	      cmd="#{GIT_BIN} --git-dir #{target('')} log --raw --date=iso --pretty=fuller -1 #{type_tree} -- #{shell_quote path}" 
	    end
        
        rev=check_revision(rev)
        path='' if path.nil?
        cmd="#{GIT_BIN} --git-dir #{target('')} log --raw --date=iso --pretty=fuller --decorate -1 #{shell_quote rev} -- #{shell_quote path}" 
 
	    rev=[]
	    i=0
	    shellout(cmd) do |io|
	      files=[]
	      changeset = {}
	      parsing_descr = 0  #0: not parsing desc or files, 1: parsing desc, 2: parsing files

	      io.each_line do |line|
          if line =~ /^commit ([0-9a-f]{40})? ?(.*)$/
		  key = "commit"
		  value = $1
		  if (parsing_descr == 1 || parsing_descr == 2)
		    parsing_descr = 0
		    rev = Revision.new({:identifier => changeset[:identifier],
					:scmid => changeset[:commit],
					:author => changeset[:author],
					:time => Time.parse(changeset[:date]),
					:message => changeset[:description],
					:paths => files
				       })
		    changeset = {}
		    files = []
		  end
		  changeset[:commit] = $1
          changeset[:identifier] = $1
          changeset[:name] = ($2 != '') ? $2 : $1
		elsif (parsing_descr == 0) && line =~ /^(\w+):\s*(.*)$/
		  key = $1
		  value = $2
		  if key == "Author"
		    changeset[:author] = value
		  elsif key == "CommitDate"
		    changeset[:date] = value
		  end
		elsif (parsing_descr == 0) && line.chomp.to_s == ""
		  parsing_descr = 1
		  changeset[:description] = ""
		elsif (parsing_descr == 1 || parsing_descr == 2) && line =~ /^:\d+\s+\d+\s+[0-9a-f.]+\s+[0-9a-f.]+\s+(\w)\s+(.+)$/
		  parsing_descr = 2
		  fileaction = $1
		  filepath = $2
		  files << {:action => fileaction, :path => "refs/#{type_tree}/#{filepath}"}
		elsif (parsing_descr == 1) && line.chomp.to_s == ""
		  parsing_descr = 2
		elsif (parsing_descr == 1)
		  changeset[:description] << line
		end
	      end	
	      rev = Revision.new({:identifier => changeset[:identifier],
				  :scmid => changeset[:commit],
				  :author => changeset[:author],
				  :time => (changeset[:date] ? Time.parse(changeset[:date]) : nil),
				  :message => changeset[:description],
				  :paths => files
				 })

	    end

	    get_rev('latest',treepath) if rev == []

	    return nil if $? && $?.exitstatus != 0
	    return rev
        end

        def info
          revs = revisions('','--all',nil,{:limit => 1})
          if revs && revs.any?
            Info.new(:root_url => '', :lastrev => revs.first)
          else
            nil
          end
        rescue Errno::ENOENT => e
          return nil
        end
        
        def entries(treepath=nil, identifier=nil)
          identifier=check_revision(identifier, false)
          treepath ||= ''
          type, tree, node_path = parse_refs(treepath)
          if type and tree
              path = node_path
          else
              type = "heads"
              tree = "master"
              path = '' 
          end
	    path ||= ''
	    entries = Entries.new
	    if !treepath.empty?
	      type_tree = "#{type}/#{tree}"
	      cmd = "#{GIT_BIN} --git-dir #{target('')} ls-tree -l "
	      cmd << shell_quote(type_tree + ":" + path + (path.empty? ? "" : "/")) if identifier.nil?
	      cmd << shell_quote(identifier + ":" + path + (path.empty? ? "" : "/")) if identifier
	      shellout(cmd)  do |io|
		io.each_line do |line|
		  e = line.chomp.to_s
		  if e =~ /^\d+\s+(\w+)\s+([0-9a-f]{40})\s+([0-9-]+)\s+(.+)$/
		    type = $1
		    sha = $2
		    size = $3
		    name = $4
		    entries << Entry.new({:name => name,
					   :path => (treepath.empty? ? name : "#{treepath}/#{name}"),
					   :kind => ((type == "tree") ? 'dir' : 'file'),
					   :size => ((type == "tree") ? nil : size),
					   #:lastrev => get_rev(identifier,(path.empty? ? name : "#{path}/#{name}")) 
					   :lastrev => get_rev(identifier,(treepath.empty? ? name : "#{treepath}/#{name}")) 
								      
					 }) unless entries.detect{|entry| entry.name == name}
		  end
		end
	      end
	    else
	      cmd = "#{GIT_BIN} --git-dir #{target('')} for-each-ref --format=#{shell_quote('%(objectname) %(objecttype) %(refname)')} refs"
	      shellout(cmd)  do |io|
		io.each_line do |line|
		  e = line.chomp.to_s
		  if e =~ /^([0-9a-f]{40})\s+\w+\s+(.+)$/
		    sha = $1
		    refname = $2
		    entries << Entry.new({:name => refname,
					   :path => refname,
					   #:path => (path.empty? ? refname : "#{path}/#{refname}"),
					   :kind => 'dir',
					   :size => nil,
					   :lastrev => get_rev(sha,(path.empty? ? refname : "#{path}/#{refname}")) 
								      
					 }) unless entries.detect{|entry| entry.name == refname}
		  end
		end
	      end
	    end
	    return nil if $? && $?.exitstatus != 0
	    entries.sort_by_name
        end
        
        def revisions(treepath, identifier_from, identifier_to, options={})
          revisions = Revisions.new
          identifier_from=check_revision(identifier_from) if identifier_from
          identifier_to=check_revision(identifier_to) if identifier_to
          treepath ||= ''
          type_tree ||= '' 
	      path ||= '' 
          type, tree, node_path = parse_refs(treepath)
          if type and tree
	          type_tree = "#{type}/#{tree}"
              path = node_path
	      end
	      cmd = "#{GIT_BIN} --git-dir #{target('')} for-each-ref --format=#{shell_quote('%(objectname) %(objecttype) %(refname)')} refs"
	      shellout(cmd)  do |io|
		io.each_line do |line|
		  e = line.chomp.to_s
		  if e =~ /^([0-9a-f]{40})\s+\w+\s+(.+)$/
		    sha = $1
		    refname = $2

		    cmd = "#{GIT_BIN} --git-dir #{target('')} log --raw --date=iso --pretty=fuller"
		    cmd << " --reverse" if options[:reverse]
            cmd << " --decorate" #if options[:decorate]
		    cmd << " -n #{options[:limit].to_i} " if (!options.nil?) && options[:limit]
            cmd << " #{shell_quote(identifier_from)} " if identifier_from
		    cmd << " #{shell_quote identifier_to} " if identifier_to
		    cmd << " #{shell_quote refname} " if identifier_from.nil? && identifier_to.nil?
            cmd << " -- #{shell_quote path}" if path
		    shellout(cmd) do |io|
		      files=[]
		      changeset = {}
		      parsing_descr = 0  #0: not parsing desc or files, 1: parsing desc, 2: parsing files
		      revno = 1

		      io.each_line do |line|
              if line =~ /^commit ([0-9a-f]{40})? ?(.*)$/
			  key = "commit"
			  value = $1
			  if (parsing_descr == 1 || parsing_descr == 2)
			    parsing_descr = 0
			    revision = Revision.new({:identifier => changeset[:identifier],
						     :scmid => changeset[:commit],
						     :author => changeset[:author],
						     :time => Time.parse(changeset[:date]),
						     :message => changeset[:description],
						     :paths => files
						    })
			    if block_given?
			      yield revision
			    else
			      revisions << revision
			    end
			    changeset = {}
			    files = []
			    revno = revno + 1
			  end
			  changeset[:commit] = $1
              changeset[:identifier] = $1
              changeset[:name] = ($2 != '') ? $2 : $1
			elsif (parsing_descr == 0) && line =~ /^(\w+):\s*(.*)$/
			  key = $1
			  value = $2
			  if key == "Author"
			    changeset[:author] = value
			  elsif key == "CommitDate"
			    changeset[:date] = value
			  end
			elsif (parsing_descr == 0) && line.chomp.to_s == ""
			  parsing_descr = 1
			  changeset[:description] = ""
			elsif (parsing_descr == 1 || parsing_descr == 2) && line =~ /^:\d+\s+\d+\s+[0-9a-f.]+\s+[0-9a-f.]+\s+(\w)\s+(.+)$/
			  parsing_descr = 2
			  fileaction = $1
			  filepath = $2
			  files << {:action => fileaction, :path => "#{refname}/#{filepath}"}
			elsif (parsing_descr == 1) && line.chomp.to_s == ""
			  parsing_descr = 2
			elsif (parsing_descr == 1)
			  changeset[:description] << line[4..-1]
			end
		      end	

		      if changeset[:commit]
			revision = Revision.new({:identifier => changeset[:identifier],
						 :scmid => changeset[:commit],
						 :author => changeset[:author],
						 :time => Time.parse(changeset[:date]),
						 :message => changeset[:description],
						 :paths => files
						})
			if block_given?
			  yield revision
			else
			  revisions << revision
			end
		      end
	            end
		  end
		end
	      end

          return nil if $? && $?.exitstatus != 0
          revisions
        end
        
        def diff(treepath, identifier_from, identifier_to=nil)
          treepath ||= ''
	      path ||= '' 
          type, tree, node_path = parse_refs(treepath)
          if type and tree
	          type_tree = "#{type}/#{tree}"
              path = node_path
          else
            type = "heads"
            tree = "master"
            type_tree = 'heads/master'
          end
          if !identifier_to
            identifier_to = nil
          end
          identifier_from=check_revision(identifier_from, false)
          identifier_to=check_revision(identifier_to, false) if !identifier_to.nil?
          
          cmd = "#{GIT_BIN} --git-dir #{target('')} show #{shell_quote identifier_from}" if identifier_to.nil?
          cmd = "#{GIT_BIN} --git-dir #{target('')} diff #{shell_quote identifier_to} #{shell_quote identifier_from}" if !identifier_to.nil?
          cmd << " -- #{shell_quote path}" unless path.empty?
          diff = []
          shellout(cmd) do |io|
            io.each_line do |line|
              diff << line
            end
          end
          return nil if $? && $?.exitstatus != 0
          diff
        end
        
        def annotate(treepath, identifier=nil)
          treepath ||= ''
          type, tree, node_path = parse_refs(treepath)
          if type and tree
	          type_tree = "#{type}/#{tree}"
              path = node_path
          else
              type = "heads"
              tree = "master"
              path = '' 
              type_tree = 'heads/master'
          end
          identifier=check_revision(identifier, false)
          cmd = "#{GIT_BIN} --git-dir #{target('')} blame -l #{shell_quote identifier} -- #{shell_quote path}"
          blame = Annotate.new
          content = nil
          shellout(cmd) { |io| io.binmode; content = io.read }
          return nil if $? && $?.exitstatus != 0
          # git annotates binary files
          return nil if content.is_binary_data?
          content.split("\n").each do |line|
            next unless line =~ /([0-9a-f]{39,40})\s\((\w*)[^\)]*\)(.*)/
            blame.add_line($3.rstrip, Revision.new(:identifier => $1, :author => $2.strip))
          end
          blame
        end
        
        def cat(treepath, identifier=nil)
          treepath ||= ''
          type, tree, node_path = parse_refs(treepath)
          if type and tree
	          type_tree = "#{type}/#{tree}"
              path = node_path
          else
              type = "heads"
              tree = "master"
              path = '' 
              type_tree = 'heads/master'
          end
          if identifier.nil?
            identifier = 'HEAD'
          end
          cmd = "#{GIT_BIN} --git-dir #{target('')} show #{shell_quote(identifier + ':' + path)}"
          cat = nil
          shellout(cmd) do |io|
            io.binmode
            cat = io.read
          end
          return nil if $? && $?.exitstatus != 0
          cat
        end
      end
    end
  end

end

