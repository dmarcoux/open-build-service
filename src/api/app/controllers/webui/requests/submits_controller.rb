module Webui
  module Requests
    class SubmitsController < WebuiController
      before_action :require_package, only: [:new]

      def new
        @project = @package.project
        @revision = params[:revision] || @package.rev
      end

      def create
        target_project_name = params[:targetproject].try(:strip)
        package_name = params[:package].strip
        project_name = params[:project].strip

        if params[:targetpackage].blank?
          target_package_name = package_name
        else
          target_package_name = params[:targetpackage].try(:strip)
        end

        if target_project_name.blank?
          flash[:error] = 'Please provide a target for the submit request'
          redirect_to action: :show, project: project_name, package: package_name
          return
        end

        req = nil
        begin
          BsRequest.transaction do
            req = BsRequest.new(state: 'new')
            req.description = params[:description]

            opts = { source_project: project_name,
                     source_package: package_name,
                     target_project: target_project_name,
                     target_package: target_package_name }
            if params[:sourceupdate]
              opts[:sourceupdate] = params[:sourceupdate]
            elsif params[:project].include?(':branches:')
              opts[:sourceupdate] = 'update' # Avoid auto-removal of branch
            end
            opts[:source_rev] = params[:rev] if params[:rev]
            action = BsRequestActionSubmit.new(opts)
            req.bs_request_actions << action

            req.set_add_revision
            req.save!
          end
        rescue BsRequestAction::Errors::DiffError => e
          flash[:error] = "Unable to diff sources: #{e.message}"
        rescue BsRequestAction::MissingAction => e
          flash[:error] = 'Unable to submit, sources are unchanged'
        rescue ::Project::UnknownObjectError,
               BsRequestAction::UnknownProject,
               BsRequestAction::UnknownTargetPackage => e
          redirect_back(fallback_location: root_path, error: "Unable to submit (missing target): #{e.message}")
          return
        rescue APIError, ActiveRecord::RecordInvalid => e
          flash[:error] = "Unable to submit: #{e.message}"
        rescue ActiveRecord::RecordInvalid => e
          flash[:error] = "Unable to submit: #{e.message}"
        end

        if flash[:error]
          if package_name.blank?
            redirect_to(project_show_path(project: project_name))
          else
            redirect_to(package_show_path(project: project_name, package: package_name))
          end
          return
        end

        # Supersede logic has to be below addition as we need the new request id
        supersede_errors = []
        if params[:supersede_request_numbers]
          params[:supersede_request_numbers].each do |request_number|
            r = BsRequest.find_by_number!(request_number)
            opts = {
              newstate: 'superseded',
              reason: "Superseded by request #{req.number}",
              superseded_by: req.number
            }
            r.change_state(opts)
          rescue APIError => e
            supersede_errors << e.message.to_s
          end
        end

        if supersede_errors.any?
          supersede_notice = 'Superseding failed: '
          supersede_notice += supersede_errors.join('. ')
        end
        flash[:success] = "Created <a href='#{request_show_path(req.number)}'>submit request #{req.number}</a>\
                          to <a href='#{project_show_path(target_project_name)}'>#{target_project_name}</a>
                          #{supersede_notice}"
        redirect_to(action: 'show', controller: '/webui/package', project: project_name, package: package_name)
      end

    end
  end
end
