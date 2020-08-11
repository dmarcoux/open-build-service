class StatusMessageComponent < ViewComponent::Base
  # In comparison to partials, we know what is needed to render this component
  def initialize(status_message:)
    @status_message = status_message
    @policy = Current.policy_method[@status_message]
  end
end
