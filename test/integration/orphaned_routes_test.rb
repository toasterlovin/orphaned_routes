class OrphanedRoutesTest < ActionDispatch::IntegrationTest
  def defined_routes
    Rails.application.routes.routes.map do |route|
      # Turn the route path spec into a string:
      # - Remove the "(.:format)" bit at the end
      # - Use "1" for all params
      path = route.path.spec.to_s.gsub(/\(\.:format\)/, "").gsub(/:[a-zA-Z_]+/, "1")
      # Route verbs are stored as regular expressions; convert them to symbols
      verb = %W{ GET POST PUT PATCH DELETE }.grep(route.verb).first.downcase.to_sym
      # Return a hash with two keys: the route path and it's verb
      { path: path, verb: verb }
    end
  end

  test "no orphaned routes exist" do

    orphaned_routes = []

    # Ignore the assets route
    defined_routes.reject { |route| route[:path].starts_with?("/assets") }.each do |route|
      begin
        reset!
        # Use the route's verb to access the route's path
        request_via_redirect(route[:verb], route[:path])
      rescue ActionController::RoutingError, AbstractController::ActionNotFound
        # ActionController::RoutingError means the controller doesn't exist
        # AbstractController::ActionNotFound means the action doesn't exist
        orphaned_routes << "#{route[:verb]} #{route[:path]}"
      rescue ActiveRecord::RecordNotFound, ActionController::ParameterMissing
        # ActiveRecord::RecordNotFound happens because we are using 1 for all the route params
        # ActionController::ParameterMissing happens because we aren't submitting params to create or update
      end
    end

    # Fail if we have any orphaned routes
    assert orphaned_routes.empty?,
      "The following routes lead to nowhere: \n\t#{orphaned_routes.uniq.join("\n\t")}"
  end
end
