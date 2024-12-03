# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.config do |config|
  # Generate session nonces for permitted importmap and inline scripts
  # config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  # config.content_security_policy_nonce_directives = %w(script-src)

  # Report CSP violations to a specified URI. See:
  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
  config.content_security_policy_report_only = true
end

Rails.application.config.content_security_policy do |policy|
  policy.connect_src :self, :https
  policy.default_src :self, :https
  policy.font_src :self, :https, :data
  policy.frame_src :self, :https, 'www.jotform.com'
  policy.img_src :self, :https, :data
  policy.object_src :none
  policy.script_src :self, :https, :unsafe_inline, :unsafe_eval
  policy.style_src :self, :https, :unsafe_inline
  policy.worker_src :self, :https, :data, :blob, :unsafe_inline
  policy.report_uri '/csp-violation-report-endpoint'
end
