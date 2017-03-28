require_relative 'test_helper'

class UserForm
  def self.create
    {
      "type" => "object",
      "properties": {
        "data": {
          "type" => "object",
          "properties" => {
            "attributes" => {
              "type" => "object",
              "properties" => {
                "first_name" => {
                  "type" => "string"
                },
                "last_name" => {
                  "type" => "string"
                }
              },
              "required" => [
                "first_name"
              ]
            },
            "type" => {
              "type" => "string",
              "enum" => [ "users" ]
            }
          },
          "required" => [
            "attributes",
            "type"
          ]
        }
      },
      "required": [
        "data"
      ]
    }
  end

  def self.update
    {
      "type" => "object",
      "properties": {
        "data": {
          "type" => "object",
          "properties" => {
            "attributes" => {
              "type" => "object",
              "properties" => {
                "first_name" => {
                  "type" => "string"
                },
                "last_name" => {
                  "type" => "string"
                }
              }
            },
            "id" => {
              "type" => "string"
            },
            "type" => {
              "type" => "string",
              "enum" => [ "users" ]
            }
          },
          "required" => [
            "attributes",
            "id",
            "type"
          ]
        }
      },
      "required": [
        "data"
      ]
    }
  end
end

class UserRelationshipsMotherForm
  def self.update
    form
  end

  def self.delete
    form
  end

  def self.form
    {
      "type" => "object",
      "properties": {
        "data": {
          "type" => "object",
          "properties" => {
            "id" => {
              "type" => "string"
            },
            "type" => {
              "type" => "string",
              "enum" => [ "mothers" ]
            }
          },
          "required" => [
            "id",
            "type"
          ]
        }
      },
      "required": [
        "data"
      ]
    }
  end
  private_class_method :form
end

class NoMethodsForm
end

class UserRelationshipsThingForm
  def self.update
    {
      "type" => "object",
      "properties": {
        "data": {
          "type" => "array"
        }
      },
      "required": [
        "data"
      ]
    }
  end
end

class NoAttributesSuppliedForm
  def self.create
    {
      "type" => "object",
      "properties": {
        "data": {
          "type" => "object",
          "properties" => {
            "meta" => {
              "type" => "object"
            },
            "attributes" => {
              "type" => "object",
              "properties" => {
                "foo" => {
                  "type" => "object"
                }
              }
            },
            "type" => {
              "type" => "string",
              "enum" => [ "no_attributes" ]
            }
          },
          "required" => [
            "meta",
            "type"
          ]
        }
      },
      "required": [
        "data"
      ]
    }
  end
end

class RequestValidatorTest < Minitest::Test
  def setup
    @app = lambda { |env| [200, {}, []] }
    @validator = Superintendent::Request::Validator.new(
      @app,
      monitored_content_types: ['application/json']
    )
  end

  def mock_env(path, method, opts={})
    Rack::MockRequest.env_for(
      path,
      {
        'CONTENT_TYPE' => 'application/json',
        method: method,
      }.merge(opts)
    )
  end

  def test_default_env
    env = Rack::MockRequest.env_for('/', { 'method': 'GET' })
    status, headers, body = @validator.call(env)
    assert_equal 200, status
  end

  def test_monitored_content
    env = mock_env('/', 'GET')
    status, headers, body = @validator.call(env)
    assert_equal 200, status
  end

  def test_monitored_content_create
    params = {
      data: {
        attributes: {
          first_name: 'Test User'
        },
        type: 'users'
      }
    }
    env = mock_env('/users', 'POST', input: JSON.generate(params))
    status, headers, body = @validator.call(env)
    assert_equal 200, status
  end

  def test_monitored_accept_update
    params = {
      data: {
        attributes: {
          first_name: 'Test User'
        },
        id: 'US5d251f5d477f42039170ea968975011b',
        type: 'users'
      }
    }
    %w[PUT PATCH].each do |method|
      env = mock_env('/users/US5d251f5d477f42039170ea968975011b', method, input: JSON.generate(params))
      status, headers, body = @validator.call(env)
      assert_equal 200, status
    end
  end

  def test_single_resource
    params = {
      data: {
        attributes: {
          first_name: 'Test User'
        },
        id: 'US5d251f5d477f42039170ea968975011b',
        type: 'users'
      }
    }
    env = mock_env('/users/US5d251f5d477f42039170ea968975011b', 'PUT', input: JSON.generate(params))
    status, headers, body = @validator.call(env)
    assert_equal 200, status
  end

  def test_single_resource_json_api
    params = {
      data: {
        attributes: {
          first_name: 'Test User'
        },
        id: 'US5d251f5d477f42039170ea968975011b',
        type: 'users'
      }
    }
    env = mock_env('/users/US5d251f5d477f42039170ea968975011b', 'PUT',
                   input: JSON.generate(params), 'CONTENT_TYPE' => 'application/vnd.api+json')
    status, headers, body = @validator.call(env)
    assert_equal 200, status
  end

  def test_optional_attributes_not_supplied
    params = {
      data: {
        meta: {},
        type: 'no_attributes'
      }
    }
    env = mock_env('/no_attributes_supplied/NA1111111111111111111111111111111', 'POST',
                   input: JSON.generate(params), 'CONTENT_TYPE' => 'application/vnd.api+json')
    status, headers, body = @validator.call(env)
    assert_equal 200, status
  end

  def test_relationships
    params = {
      data: {
        id: 'US5d251f5d477f42039170ea968975011b',
        type: 'mothers'
      }
    }
    env = mock_env('/users/US5d251f5d477f42039170ea968975011b/relationships/mother', 'PUT',
                   input: JSON.generate(params), 'CONTENT_TYPE' => 'application/vnd.api+json')
    status, headers, body = @validator.call(env)
    assert_equal 200, status
  end

  def test_relationships_400
    params = {
      data: {
        id: 'US5d251f5d477f42039170ea968975011b',
        type: 'fathers'
      }
    }
    env = mock_env('/users/US5d251f5d477f42039170ea968975011b/relationships/mother', 'PUT',
                   input: JSON.generate(params), 'CONTENT_TYPE' => 'application/vnd.api+json')
    status, headers, body = @validator.call(env)
    assert_equal 400, status
  end

  def test_relationships_no_form_404
    params = {
      data: {
        id: 'US5d251f5d477f42039170ea968975011b',
        type: 'father'
      }
    }
    env = mock_env('/users/US5d251f5d477f42039170ea968975011b/relationships/father', 'PUT',
                   input: JSON.generate(params), 'CONTENT_TYPE' => 'application/vnd.api+json')
    status, headers, body = @validator.call(env)
    assert_equal 404, status
  end

  def test_relationships_delete_200
    params = {
      data: {
        id: 'US5d251f5d477f42039170ea968975011b',
        type: 'mothers'
      }
    }
    env = mock_env('/users/US5d251f5d477f42039170ea968975011b/relationships/mother', 'DELETE',
                   input: JSON.generate(params), 'CONTENT_TYPE' => 'application/vnd.api+json')
    status, headers, body = @validator.call(env)
    assert_equal 200, status
  end

  def test_relationships_delete_400_bad_request
    params = {
      data: {
        id: 'US5d251f5d477f42039170ea968975011b'
      }
    }
    env = mock_env('/users/US5d251f5d477f42039170ea968975011b/relationships/mother', 'DELETE',
                   input: JSON.generate(params), 'CONTENT_TYPE' => 'application/vnd.api+json')
    status, headers, body = @validator.call(env)
    assert_equal 400, status
  end

  def test_relationships_delete_400_no_body
    env = mock_env('/users/US5d251f5d477f42039170ea968975011b/relationships/mother', 'DELETE',
                   'CONTENT_TYPE' => 'application/vnd.api+json')
    status, headers, body = @validator.call(env)
    assert_equal 400, status
  end

  def test_relationships_delete_404_no_form_method
    params = {
      data: {
        id: 'US5d251f5d477f42039170ea968975011b',
        type: 'users'
      }
    }
    env = mock_env('/users/US5d251f5d477f42039170ea968975011b', 'DELETE',
                   input: JSON.generate(params), 'CONTENT_TYPE' => 'application/vnd.api+json')
    status, headers, body = @validator.call(env)
    assert_equal 404, status
  end

  def test_delete_200_no_body_no_form_method
    env = mock_env('/users/US5d251f5d477f42039170ea968975011b', 'DELETE',
                   'CONTENT_TYPE' => 'application/vnd.api+json')
    status, headers, body = @validator.call(env)
    assert_equal 200, status
  end

  def test_no_form_method
    ['POST', 'PATCH', 'PUT'].each do |verb|
      env = mock_env('/no_methods/NM5d251f5d477f42039170ea968975011b', verb,
                     'CONTENT_TYPE' => 'application/vnd.api+json')
      status, headers, body = @validator.call(env)
      assert_equal 404, status
    end

  end

  def test_plural_relationships_use_singular_form
    params = {
      data: []
    }
    env = mock_env('/users/US5d251f5d477f42039170ea968975011b/relationships/things', 'PUT',
                   input: JSON.generate(params), 'CONTENT_TYPE' => 'application/vnd.api+json')
    status, headers, body = @validator.call(env)
    assert_equal 200, status
  end

  def test_no_form_404
    env = mock_env('/things', 'POST')
    status, headers, body = @validator.call(env)
    assert_equal 404, status
  end

  def test_nested_resource_no_form_404
    env = mock_env('/users/US5d251f5d477f42039170ea968975011b/things', 'POST')
    status, headers, body = @validator.call(env)
    assert_equal 404, status
  end

  def test_schema_conflict
    params = {
      attributes: {
        first_name: 123
      },
      type: 'users'
    }
    env = mock_env('/users', 'POST', input: JSON.generate(params))
    status, headers, body = @validator.call(env)
    assert_equal 400, status
  end

  def test_400_missing_required_attribute
    params = {
      attributes: {
        last_name: 'Jones'
      },
      type: 'users'
    }
    env = mock_env('/users', 'POST', input: JSON.generate(params))
    status, headers, body = @validator.call(env)
    assert_equal 400, status
  end
end
