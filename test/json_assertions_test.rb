require 'json_assertions'
require "minitest/autorun"


class JsonAssertionsTest < Minitest::Test
  include JsonAssertions

  def json_response
    {"users" => [
       {"id" => 1, "name" => "Bob"},
       {"id" => 2, "name" => "Sally"}
     ]}
  end
  
  def test_basic_assertions
    assert_json_equal("Bob", "/users/0/name")
    assert_json_match(/o/, "/users/0/name")
    assert_json_missing("/users/0/password")
    assert_json_has("/users/1/name")
    assert_json_array_size(2, "/users")
    assert_json_is_array("/users/")
  end
  
  def test_assertion_failure
    assert_raises(Minitest::Assertion) {assert_json_equal("XXX", "/users/0/name")}
    assert_raises(Minitest::Assertion) {assert_json_match(/xxx/, "/users/0/name")}
    assert_raises(Minitest::Assertion) {assert_json_missing("/users/0/id")}
    assert_raises(Minitest::Assertion) {assert_json_has("/users/1/password")}
    assert_raises(Minitest::Assertion) {assert_json_array_size(666, "/users")}
    assert_raises(Minitest::Assertion) {assert_json_is_array("/admins/")}
  end


  def test_with_json
    with_json(JSON.dump json_response) do|json|
      json.equal("Bob", "/users/0/name")
      json.matches(/o/, "/users/0/name")
      json.must_have("/users/1/name")
      json.must_not_have("/users/1/password")
      json.array_size_is(2, "/users")
      json.array_size_gte(1, "/users")
      json.array_map_equals([1,2], "/users", '/id')
      
      json.is_array?("/users/")
      assert_equal 1, json.value_at("/users/0/id")
    end
  end
  
end

