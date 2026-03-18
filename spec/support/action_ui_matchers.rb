RSpec::Matchers.define :show_action_element do |expected|
  match do |response|
    body = response.respond_to?(:body) ? response.body : response.to_s
    if expected.is_a?(Regexp)
      body.match?(expected)
    else
      body.include?(expected.to_s)
    end
  end

  failure_message do |response|
    body = response.respond_to?(:body) ? response.body : response.to_s
    "expected response body to include #{expected.inspect}, but it did not"
  end
end

RSpec::Matchers.define :hide_action_element do |expected|
  match do |response|
    body = response.respond_to?(:body) ? response.body : response.to_s
    if expected.is_a?(Regexp)
      !body.match?(expected)
    else
      !body.include?(expected.to_s)
    end
  end

  failure_message do |response|
    body = response.respond_to?(:body) ? response.body : response.to_s
    "expected response body to NOT include #{expected.inspect}, but it did"
  end
end
