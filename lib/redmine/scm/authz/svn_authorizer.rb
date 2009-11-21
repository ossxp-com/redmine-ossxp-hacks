require File.dirname(__FILE__) + '/inifile'

class SvnAuthorizer

  def initialize(authz_file, module_name, user)
    @authz_file = authz_file.nil? ? '' : authz_file
    @conf_authz = IniFile.new @authz_file
    @module_name = module_name
    @user = user
    @aliases = get_aliases
    @groups = get_groups
  end

  def has_permission?(path=nil)
    #when @authz_file is empty string,meanning user current redmine authority policy
    return true if @authz_file.empty?
    #when @authz_file isn't empty string,but inifile match empty,meanning authz file path wrong
    return false if @conf_authz.to_s.empty?
    
    return false if path.nil? || path.empty?
    parent_paths = []
    parent_iterate(path) {|p| parent_paths << p}
    for p in parent_paths
      if !@module_name.empty?
        perms = []
        get_section(@module_name+":"+p) {|allow| perms << allow}
        for perm in perms
          return perm unless perm.nil?
        end
      end

      #section exclude repostory: authority for example
      #[/trunk/src]
      #user1 = r        
      perms = []
      get_section(p) {|allow| perms << allow}
      for perm in perms
        return perm unless perm.nil?
      end
    end
    return false
  end

  def parent_iterate(path)
    path = path.sub(/^\/|\/$/,'')
    if !path.empty?
      path = '/' + path + '/'
    else
      path = '/'
    end  
    while true
      yield path
      break if path == '/'
      path = path[0..-2]
      yield path
      index = path.rindex('/')
      path = path[0..index]
    end
  end
  
  def get_aliases
    return [] unless @conf_authz.has_section?("aliases") || !@user.nil?
    user_aliases = []
    for ali in @conf_authz["aliases"].keys
      member = @conf_authz["aliases"][ali].strip
      user_aliases << ali if member == @user
    end
    return user_aliases
  end

  def get_groups
    return [] unless @conf_authz.has_section?("groups") || !@user.nil?
    @grp_parents = {}
    @grp_parents.default=[]
    user_groups = []
    for group in @conf_authz["groups"].keys
      for member in @conf_authz["groups"][group].split(',')
        member.strip!
        if member == @user
          user_groups << group
        elsif member.start_with?("@")
          member = member[1..-1] 
          if @grp_parents.has_key? member
            @grp_parents[member] << group
          else
            @grp_parents[member] = [group]
          end
        elsif member.start_with?("&")
          member = member[1..-1]
          user_groups << group if @aliases.include?(member)
        end
      end
    end

    @expanded = {}

    for g in user_groups
      expand_group(g)
    end
    
    return @expanded.keys
  end
    
  def expand_group(group)
    return if @expanded.include? group
      @expanded[group] = true
    for parent in @grp_parents[group]
      expand_group(parent)
    end
  end

  def get_section(section)
    return unless @conf_authz.has_section? section

    matched = false

    #check current user authority
    user_perm = get_permission(section, @user)
    yield user_perm
    matched |= !user_perm.nil?
    
    #check current user alias authority
    alias_perm = nil
    for a in @aliases
      p = get_permission(section, '&'+a)
      alias_perm = p unless p.nil?
      if alias_perm
        yield true
        break
      end
    end
    matched |= !alias_perm.nil?

    #check current user group authority
    group_perm = nil
    for g in @groups
      p = get_permission(section,'@'+g)
      group_perm = p unless p.nil?
      if group_perm
        yield true
        break
      end
    end
    matched |= !group_perm.nil?

    #check all users,including anonymous authority
    pan_perm = get_permission(section,'*')
    yield true if pan_perm
    matched |= !pan_perm.nil?

    #check $ role authority
    role_perm = nil
    if @user.nil? || @user == 'annoymous'
      role_perm = get_permission(section,'$anonymous')
    else
      role_perm = get_permission(section,'$authenticated')
    end
    yield true if role_perm
    matched |= !role_perm.nil?
    
    if matched
      yield false
    else
      yield nil
    end
  end

  def get_permission(section, subject)
    return get(section, subject).include?('r') if has_option?(section,subject)
  end

  def has_option?(section, subject)
    @conf_authz[section].has_key? subject
  end

  def get(section, subject)
    @conf_authz[section][subject].split('')
  end
end

