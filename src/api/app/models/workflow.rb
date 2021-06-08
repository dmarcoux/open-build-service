class Workflow
  SUPPORTED_STEPS = { 'branch_package' => Workflow::Step::BranchPackageStep }.freeze

  def initialize(workflow:, scm_extractor_payload:, token:)
    @workflow = workflow
    @scm_extractor_payload = scm_extractor_payload
    @token = token
  end

  def steps
    steps = []
    return steps if @workflow['steps'].blank?

    @workflow['steps'].each do |step|
      step.each do |step_name, step_instructions|
        next if SUPPORTED_STEPS[step_name].blank?

        new_step = SUPPORTED_STEPS[step_name].new(step_instructions: step_instructions, scm_extractor_payload: @scm_extractor_payload, token: @token)
        steps << new_step if new_step.allowed_event_and_action? # TODO: Use BranchPackageStepValidator.new.validate(new_step)
      end
    end
    steps
  end
end
