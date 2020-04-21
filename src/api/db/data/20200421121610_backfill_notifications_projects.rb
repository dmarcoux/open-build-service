class BackfillNotificationsProjects < ActiveRecord::Migration[6.0]
  def up
    Notification.where.not(notifiable_type: nil, notifiable_type: nil).find_each do |notification|
      case notification.notifiable_type
      when 'BsRequest'
        notification.projects << notifiable.target_project_objects.uniq
      when 'Comment'
        case notifiable.commentable_type
        when 'Project'
          notification.projects << notifiable.commentable
        when 'Package'
          notification.projects << notifiable.commentable.project
        when 'BsRequest'
          notification.projects << notifiable.commentable.target_project_objects.uniq
      when 'Review'
        notification.projects << notifiable.bs_request.target_project_objects.uniq
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
