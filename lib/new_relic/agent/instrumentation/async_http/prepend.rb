# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'instrumentation'

module NewRelic::Agent::Instrumentation
  module AsyncHttp::Prepend
    include NewRelic::Agent::Instrumentation::AsyncHttp

    def call(*args)
      call_with_new_relic(*args) { super }
    end
  end
end
