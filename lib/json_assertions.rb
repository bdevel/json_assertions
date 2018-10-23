require 'json'

module JsonAssertions

  # Prettifies json
  def pretty_json(json)
    hash = JSON.parse json
    JSON.pretty_generate(hash)
  end

  # Parse the response body for you.
  def json_response
    JSON.parse response.body
  end

  def assert_json_equal(expected, path, message=nil)
    JsonResponseTester.new(json_response, self).equal(expected, path, message)
  end


  def assert_json_match(regex, path, message=nil)
    JsonResponseTester.new(json_response, self).matches(regex, path, message)
  end

  def assert_json_missing(path, message=nil)
    JsonResponseTester.new(json_response, self).must_not_have(path, message)
  end

  def assert_json_has(path, message=nil)
    JsonResponseTester.new(json_response, self).must_have(path, message)
  end

  def assert_json_array_size(expected, path, message=nil)
    assert_equal expected, JsonResponseTester.new(json_response, self).value_at(path).size, message
  end

  def assert_json_is_array(path, message=nil)
    JsonResponseTester.new(json_response, self).is_array?(path, message)
  end
 
  def with_json(json, &block)
    block.call JsonResponseTester.new(json, self)
  end


  class JsonResponseTester

    def initialize(json, controller_test)
      @controller_test = controller_test
      if json.class == String
        begin
          @json_hash = JSON.parse json
        rescue Exception
          test_failure "Could not parse JSON string \"#{json.slice(0, 100)}\""
        end
      else
        @json_hash = json
      end
    end

    def [](key)
      return @json_hash[key]
    end


    # equal
    # @param expected
    # @path
    def equal(expected, path, message=nil)
      value = value_at(path)
      
      if value != expected
        error_msg = message || "JSON value #{value} != #{expected} at path #{path}"
        test_failure error_msg, path
      else
        @controller_test.assert true
      end
    end
    alias :equals :equal

    def matches(regex, path, message=nil)
      unless regex =~ value_at(path)
        error_msg = message || "JSON value of #{value_at(path).inspect} at path #{path} does not match #{regex}."
        test_failure error_msg, path
      else
        @controller_test.assert true
      end
      true
    end

    def must_have(path, message=nil)
      error_msg = message || "JSON path #{path} does not exist but is expected."
      begin
        value = value_at(path)
        if value.nil?
          test_failure error_msg, path
        else
          @controller_test.assert true
        end
      rescue Exception
        test_failure error_msg, path
      end
      true
    end

    def must_not_have(path, message=nil)
      value = value_at(path)
      if value != nil
        error_msg = message || "JSON path #{path} exists but expected to be missing."
        test_failure error_msg, path
      else
        @controller_test.assert true
      end
      return true
    end

    def array_size_gte(expected_size, path, message=nil)
      is_array?(path)
      value = value_at(path)
      unless value.size >= expected_size
        error_msg = message || "JSON array at #{path} expected to be gte #{expected_size} elements but has #{value.size}."
        test_failure error_msg, path
      else
        @controller_test.assert true
      end
    end


    def array_size_is(expected_size, path, message=nil)
      is_array?(path)
      value = value_at(path)
      unless value.size == expected_size
        error_msg = message || "JSON array at #{path} expected have #{expected_size} elements but has #{value.size}."
        test_failure error_msg, path
      else
        @controller_test.assert true
      end
    end
    alias :array_length_is :array_size_is

    def is_array?(path, message=nil)
      if value_at(path).class != Array
        error_msg = message || "JSON at path #{path} expected to be an array."
        test_failure error_msg, path
      else
        @controller_test.assert true
      end
    end
    alias :is_array :is_array?

    def array_map_equals(expected_list, list_path, value_path, message=nil)
      value_list = value_at(list_path).map do |hash|

        last = hash

        value_path.split('/').each do |index|
          next if index == ''

          if index =~ /\d/
            last = last[index.to_i]
          else
            last = last[index]
          end

        end
        last
      end

      if expected_list != value_list
        error_msg = message || "List did not equal #{expected_list.inspect} #{value_list.inspect}"
        test_failure error_msg
      else
        @controller_test.assert true
      end
    end


    def value_at(path, message=nil)
      if path[0] != '/'
        error_msg = message || "Currently we can only scan JSON from base. Start path with /"
        test_failure error_msg
      end

      last = @json_hash

      path.split('/').each do |index|
        next if index == ''

        if index =~ /\d/
          #puts last.inspect
          #puts index.to_i
          last = last[index.to_i]
        else
          last = last[index]
        end

      end

      return last
    rescue TypeError
      test_failure "JSON path #{path} is not the type expected. Array instead of object perhaps."
    rescue NoMethodError
      test_failure "JSON path #{path} does not exist.", path
    end

    private

    def test_failure(message, path='')
      if @json_hash
        simple_hash = simplify_json(@json_hash, path)
        message += "\n" + JSON.pretty_generate(simple_hash)
      end
      @controller_test.assert false, message
    end

    # Shortens arrays, remove extra keys
    def simplify_json(json, path)
      out_json = json.clone

      # Allow for passing in a blank path
      if path != ''
        next_path = path.sub(/^\/[^\/]+/, '') # remove first path
        current_search = path.split('/')[1] # Root search name /search/other
      else
        next_path = ''
        current_search = nil
      end

      if json.class == Array
        out_json = [ json[0] ]
        out_json << "... (#{json.size} total) ..." if json.size > 1

        return out_json
      end

      if json.class == Hash
        json.each do |key, value|
          
          # Only include keys that were in the path
          
          if current_search != nil && current_search != key
            out_json.delete(key)
            # but return a list of the keys
            out_json['__additional keys__'] = json.keys
            next
          end

          if value.class == Array && value.length > 0
            out_json[key] =  [simplify_json(value[0], next_path)]
            out_json[key] << "... (#{value.size} total) ..." if value.size > 1

          elsif value.class == Hash
            out_json[key] = simplify_json(json[key], next_path)
          else
            out_json[key] = value
          end

        end
      end

      return out_json
      
    end
    
  end
end
