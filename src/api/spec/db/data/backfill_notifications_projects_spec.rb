require 'rails_helper'
require Rails.root.join('db/data/20200421121610_backfill_notifications_projects.rb')

RSpec.describe BackfillNotificationsProjects, type: :migration do
  describe 'up' do
    let!(:bs_request_with_submit_action) { create(:bs_request_with_submit_action) }
    let!(:user_review) { create(:user_review) }
    let!(:comment_for_project) { create(:comment_for_project) }
    let!(:comment_for_package) { create(:comment_for_package) }
    let!(:comment_for_request) { create(:comment_for_request) }

    before do
      create(:notification, :request_state_change, notifiable: bs_request_with_submit_action))
      create(:notification, :review_wanted, notifiable: user_review)
      create(:notification, :comment_for_project, notifiable: comment_for_project)
      create(:notification, :comment_for_package, notifiable: comment_for_package)
      create(:notification, :comment_for_request, notifiable: comment_for_request)

      BackfillNotificationsProjects.new.up
    end

    it 'backfills the notifications_projects table with all projects from existing notifications' do
      expect(NotificationProject.pluck(:project_id)).to eq([
        bs_request_with_submit_action.target_projects.uniq.map(&:id),
        user_review.bs_request.target_projects.uniq.map(&:id),
        comment_for_project.commentable.id,
        comment_for_package.commentable.project_id,
        comment_for_request.commentable.bs_request.target_projects.uniq.map(&:id)
      ].flatten!)
    end
  end
end
