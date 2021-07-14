class Workflow
  module Step
    class ConfigureRepositories
      include ActiveModel::Model

      def initialize(step_instructions:, scm_extractor_payload:, token:)
        @step_instructions = step_instructions.with_indifferent_access
        @scm_extractor_payload = scm_extractor_payload.with_indifferent_access
        @token = token
      end

      def call(options = {})

      end

      # TODO: Refactor Workflow model to not expect that every step has this method. This doesn't belong in steps, it's validation for the Workflow model.
      def allowed_event_and_action?
        true
      end
    end
  end
end
