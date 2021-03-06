require 'test/unit'

require 'rubygems'
require 'rack/mock'

require File.join(File.dirname(__FILE__), '..', 'lib', 'noie')

class TestApp
  def call(env)
    [200, {}, ['Hi Internets!']]
  end
end

class NoieTest < Test::Unit::TestCase

  def test_redirects_to_where_it_should_if_ie
    request  = Rack::MockRequest.new(Rack::NoIE.new(TestApp.new, {:redirect => 'http://slashdot.org'}))
    response = request.get('/', {'HTTP_USER_AGENT' => 'MSIE 6.0' })
    assert_equal 301, response.status
    assert_equal response.location, 'http://slashdot.org'
  end

  def test_redirects_to_where_it_should_if_user_specified_minimum_not_met
    request  = Rack::MockRequest.new(Rack::NoIE.new(TestApp.new, {:redirect => 'http://slashdot.org', :minimum => 6.0}))
    response = request.get('/', {'HTTP_USER_AGENT' => 'Mozilla/4.0 (compatible; MSIE 5.5b1; Mac_PowerPC)' })
    assert_equal 301, response.status
    assert_equal response.location, 'http://slashdot.org'
  end

  def test_redirects_to_local_urls
    request  = Rack::MockRequest.new(Rack::NoIE.new(TestApp.new, {:redirect => '/foo'}))
    response = request.get('/foo', {'HTTP_USER_AGENT' => 'MSIE 6.0' })
    assert_equal "Hi Internets!", response.body
  end

  def test_allows_if_not_ie
    request  = Rack::MockRequest.new(Rack::NoIE.new(TestApp.new, {:redirect => 'http://slashdot.org'}))
    response = request.get('/', {'HTTP_USER_AGENT' => 'Mozilla/5.0'})
    assert_equal "Hi Internets!", response.body
  end

  def test_dotnet_soap_client_is_not_considered_ie
    request  = Rack::MockRequest.new(Rack::NoIE.new(TestApp.new, {:redirect => 'http://slashdot.org'}))
    response = request.get('/', {'HTTP_USER_AGENT' => 'Mozilla/4.0 (compatible; MSIE 6.0; MS Web Services Client Protocol 2.0.50727.3615)'})
    assert_equal "Hi Internets!", response.body
  end

  def test_allows_if_UA_version_greater_than_minimum
    request  = Rack::MockRequest.new(Rack::NoIE.new(TestApp.new, {:redirect => 'http://slashdot.org'}))
    response = request.get('/', {'HTTP_USER_AGENT' => 'Mozilla/4.0 (compatible; MSIE 8.0; Windows XP)'})
    assert_equal "Hi Internets!", response.body
  end

  def test_allows_if_no_UA_version_no_available
    request  = Rack::MockRequest.new(Rack::NoIE.new(TestApp.new, {:redirect => 'http://slashdot.org'}))
    response = request.get('/', {'HTTP_USER_AGENT' => 'Mozilla/4.0 (compatible; MSIE l4me; Windows XP)'})
    assert_equal "Hi Internets!", response.body
  end

  def test_allows_if_no_user_agent_specified
    request  = Rack::MockRequest.new(Rack::NoIE.new(TestApp.new, {:redirect => 'http://slashdot.org'}))
    response = request.get('/')
    assert_equal "Hi Internets!", response.body
  end

  def test_except_option_allows_request_if_path_is_in_list
    request  = Rack::MockRequest.new(Rack::NoIE.new(TestApp.new, {:redirect => 'http://slashdot.org', :except => '/ie6permitted'}))
    response = request.get('/ie6permitted', {'HTTP_USER_AGENT' => 'MSIE 6.0' })
    assert_equal "Hi Internets!", response.body
  end

  def test_except_option_redirects_if_path_is_not_in_list
    request  = Rack::MockRequest.new(Rack::NoIE.new(TestApp.new, {:redirect => 'http://slashdot.org', :except => '/ie6permitted'}))
    response = request.get('/', {'HTTP_USER_AGENT' => 'MSIE 6.0' })
    assert_equal 301, response.status
    assert_equal response.location, 'http://slashdot.org'
  end

  def test_only_option_allows_request_if_path_is_not_in_list
    request  = Rack::MockRequest.new(Rack::NoIE.new(TestApp.new, {:redirect => 'http://slashdot.org', :only => '/ie6notpermitted'}))
    response = request.get('/', {'HTTP_USER_AGENT' => 'MSIE 6.0' })
    assert_equal "Hi Internets!", response.body
  end

  def test_only_option_redirects_if_path_is_in_list
    request  = Rack::MockRequest.new(Rack::NoIE.new(TestApp.new, {:redirect => 'http://slashdot.org', :only => '/ie6notpermitted'}))
    response = request.get('/ie6notpermitted', {'HTTP_USER_AGENT' => 'MSIE 6.0' })
    assert_equal 301, response.status
    assert_equal response.location, 'http://slashdot.org'
  end

end