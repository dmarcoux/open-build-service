# Neat solution shamelessly stolen from https://github.com/github/view_component/issues/310#issuecomment-650823756
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :policy_method
end
