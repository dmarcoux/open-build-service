class NotificationProject < ApplicationRecord
  belongs_to :notification
  belongs_to :project
end
