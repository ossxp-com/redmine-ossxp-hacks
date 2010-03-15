require 'test/unit'
require File.dirname(__FILE__) + '/../svn_authorizer'

class SvnAuthorizerTest < Test::Unit::TestCase
  def setup
    @user1_repos1 = SvnAuthorizer.new "svn_authorizer.ini","repos1","user1"
    @user1 = SvnAuthorizer.new "svn_authorizer.ini","","user1"
    @user2_repos1 = SvnAuthorizer.new "svn_authorizer.ini","repos1","user2"
    @user2 = SvnAuthorizer.new "svn_authorizer.ini","","user2"
    @user3_repos1 = SvnAuthorizer.new "svn_authorizer.ini","repos1","user3"
    @user4_repos1 = SvnAuthorizer.new "svn_authorizer.ini","repos1","user4"
    @user4 = SvnAuthorizer.new "svn_authorizer.ini","","user4"
    @user5 = SvnAuthorizer.new "svn_authorizer.ini","","user5"
    @anonymous = SvnAuthorizer.new "svn_authorizer.ini","","anonymous"
    @authenticated = SvnAuthorizer.new "svn_authorizer.ini","","user4"
  end
  
  def test_user1_repos1
    assert_equal [],@user1_repos1.get_aliases
    assert_equal ['team1','dev'],@user1_repos1.get_groups
    assert_equal false,@user1_repos1.has_permission?('/trunk/src/test')
    assert_equal true,@user1_repos1.has_permission?('/dev/src/test')
    assert_equal false,@user1_repos1.has_permission?('/admin/src/test')
  end

  def test_user1
    assert_equal true,@user1.has_permission?('/trunk/src/test')
  end
  
  def test_user2_repos1
    assert_equal ['admin'],@user2_repos1.get_aliases
    assert_equal ['team2','dev'],@user2_repos1.get_groups
    assert_equal true,@user2_repos1.has_permission?('/trunk/src/test')
    assert_equal true,@user2_repos1.has_permission?('/dev/src/test')
    assert_equal true,@user2_repos1.has_permission?('/admin/src/test')
  end

  def test_user2
    assert_equal false,@user2.has_permission?('/trunk')
  end
  
  def test_user3_repos1
    assert_equal [],@user3_repos1.get_aliases
    assert_equal [],@user3_repos1.get_groups
    assert_equal false,@user3_repos1.has_permission?('/trunk/')
    assert_equal true,@user3_repos1.has_permission?('/dev/src/test')
    assert_equal false,@user3_repos1.has_permission?('/admin/src/test')
  end

  def test_user4_repos1
    assert_equal [],@user4_repos1.get_aliases
    assert_equal [],@user4_repos1.get_groups
    assert_equal true,@user4_repos1.has_permission?('/trunk/')
    assert_equal true,@user4_repos1.has_permission?('/dev/src/test')
    assert_equal false,@user4_repos1.has_permission?('/admin/src/test')
  end

  def test_user4
    assert_equal true,@user4.has_permission?('/trunk')
  end

  def test_user5
    assert_equal false,@user5.has_permission?('/trunk')
  end

  def test_anonymous
    assert_equal false,@anonymous.has_permission?('/trunk')
  end

  def test_authenticated
    assert_equal true,@authenticated.has_permission?('/dev')
  end
end
