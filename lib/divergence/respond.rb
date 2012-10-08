module Divergence
  class Application < Rack::Proxy
    def call(env)
      @req = RequestParser.new(env, @g)

      if is_webhook?
        return handle_webhook
      end

      # First, lets find out what subdomain/git branch
      # we're dealing with (if any).
      unless @req.has_subdomain?
        # No subdomain, simply proxy the request.
        return perform_request(env)
      end

      # Ask our GitManager to prepare the directory
      # for the given branch.
      result = @g.prepare_directory @req.branch
      if result === false
        return error!
      end

      # And then perform the codebase swap
      @g.swap!

      fix_environment!(env)

      # Git is finished, pass the request through.
      status, header, body = perform_request(env)

      # This is super weird. Not sure why there is a status
      # header coming through, but Rack::Lint complains about
      # it, so we just remove it.
      if header.has_key?('Status')
        header.delete 'Status'
      end

      [status, header, body]
    end

    private

    def fix_environment!(env)
      env["HTTP_HOST"] = "#{config.forward_host}:#{config.forward_port}"
    end

    def error!
      Application.log.error "Branch #{@req.branch} does not exist"
      Application.log.error @req.raw
      [404, {"Content-Type" => "text/html"}, ["ERROR"]]
    end
  end
end