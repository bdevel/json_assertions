# JSON Assertions

Ruby Gem providing assert methods useful for validate JSON documents during
API development. It also supports extracting JSON values using a path syntax.


## Usage

Add to your Gemfile.

``` ruby
group :test do
  gem "json_assertions"
end
```

The module expects `response.body` method to available where ever it is
included. It should work with Rails just fine but if your framework does not
provide `response.body` then just create a `json_response` method to return
parsed JSON. There should also be an `assert` method available.


### Example

```ruby
# Rails 5
require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest

  include JsonAssertions

  test "index returns array of users item" do
    get "/users"
  
    assert_json_is_array '/users'
    assert_json_array_size 10, '/users'
    assert_json_equal 123, '/users/0/id'
    assert_json_has '/users/0/created_at'
    assert_json_equal "John Doe", '/users/0/name'
  
    # alternative syntax
    with_json response.body do |json|
      json.array_size_is 10 '/users'
      json.must_have '/users/0/id'
      json.must_not_have '/users/0/password'
      json.array_map_equals [123,456,789], '/users', '/id'
      json.equal 'John Doe', '/users/0/name'
      assert_equal 123, json["users"]["id"]
    end
  end
end

```

### Documentation

There is a simple syntax for the JSON path which is just the series of keys joined with a
slash `/`. For example, with `{"users": [{"id": 123, "name": "John"}]}` using
path `/users/0/id` would return `123`.

Generic Helpers

* `puts pretty_json(response.body)`

Available Assertions

* `assert_json_equal(expected, path, message=nil)`
* `assert_json_match(regex, path, message=nil)`
* `assert_json_missing(path, message=nil)`
* `assert_json_has(path, message=nil)`
* `assert_json_array_size(expected, path, message=nil)`
* `assert_json_is_array(path, message=nil)`

Assertions availabe when using `with_json(response.body){|j| }`

* `[](key)`
* `equal(expected, path, message=nil)`
* `matches(regex, path, message)`
* `must_have(path, message=nil)`
* `must_not_have(path, message=nil)`
* `array_size_gte(expected_size, path, message=nil)`
* `array_size_is(expected_size,path, message=nil)`
* `array_length_is(expected_size, path, message=nil)`
* `array_map_equals(expected_list, list_path, value_path, message=nil)`
* `is_array?(path, message=nil)`
* `value_at(path, message=nil)`


If the assertions fails, the error message will output a pretty version of the
response JSON which has been modified to only include nessisary details which
is helpful when working with large JSON structures.

```
1) Failure:
JsonAssertionsTest#test_with_json:
JSON path /users/1/name exists but expected to be missing.
{
  "users": [
    {
      "__additional keys__": [
        "id",
        "name"
      ]
    },
    "... (2 total) ..."
  ]
}
```


## Contribute
Contributions are welcome. Just create a fork and create a PR.


