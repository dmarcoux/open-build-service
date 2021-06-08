class BranchPackageStepValidator < ActiveModel::Validator
  def validate(record)
    allowed_event_and_action?
  end

  private

  def github_pull_request?
    @scm_extractor_payload[:scm] == 'github' && @scm_extractor_payload[:event] == 'pull_request'
  end

  def gitlab_merge_request?
    @scm_extractor_payload[:scm] == 'gitlab' && @scm_extractor_payload[:event] == 'Merge Request Hook'
  end

  def allowed_event_and_action?
    (github_pull_request? && @scm_extractor_payload[:action] == 'opened') ||
      (gitlab_merge_request? && @scm_extractor_payload[:action] == 'open')
  end
end
