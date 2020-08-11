# Preview at http://HOST:PORT/rails/view_components/status_message_component/as_anonymous_user
class StatusMessageComponentPreview < ViewComponent::Preview
  def as_anonymous_user(status_message: FactoryBot.build(:status_message, message: 'Everything is fine', created_at: Time.now))
    Current.policy_method = proc do
      StatusMessagePolicy.new(FactoryBot.build(:user_nobody), status_message)
    end
    render(StatusMessageComponent.new(status_message: status_message))
  end
end
