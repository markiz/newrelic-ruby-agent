# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.
require 'new_relic/agent/transaction_event_aggregator'
require 'new_relic/agent/synthetics_event_aggregator'
require 'new_relic/agent/transaction_event_primitive'

module NewRelic
  module Agent
    # This is responsibile for recording transaction events and managing
    # the relationship between events generated from synthetics requests
    # vs normal requests.
    class TransactionEventRecorder
      attr_reader :transaction_event_aggregator
      attr_reader :synthetics_event_aggregator

      def initialize
        @transaction_event_aggregator = NewRelic::Agent::TransactionEventAggregator.new
        @synthetics_event_aggregator = NewRelic::Agent::SyntheticsEventAggregator.new
      end

      def record payload
        return unless NewRelic::Agent.config[:'analytics_events.enabled']

        if sampled_event? payload
          transaction_event_aggregator.append_sampled { create_event(payload) }
        elsif synthetics_event? payload
          event = create_event payload
          _, rejected = synthetics_event_aggregator.append_or_reject event
          transaction_event_aggregator.append event if rejected
        else
          transaction_event_aggregator.append { create_event(payload) }
        end
      end

      def create_event payload
        TransactionEventPrimitive.create payload
      end

      def synthetics_event? payload
        payload.key? :synthetics_resource_id
      end

      SAMPLED_KEY = 'nr.sampled'

      def sampled_event? payload
        !!payload[SAMPLED_KEY]
      end

      def drop_buffered_data
        transaction_event_aggregator.reset!
        synthetics_event_aggregator.reset!
      end
    end
  end
end