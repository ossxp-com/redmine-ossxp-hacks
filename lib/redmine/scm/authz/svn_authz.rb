class SvnAuthorizer
  def initialize(authz_file, authz_module_name)
    @authz_file = authz_file
    @authz_module_name = authz_module_name
  end

  def has_permission(dir, name)
    path = dir + '/' + name
    if path =~ /^\/trunk/
      return false
    else
      return true
    end
  end
end
