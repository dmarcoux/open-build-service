module Webui
  module Requests
    class SubmissionsController < Webui::RequestController
      before_action :require_login
      before_action :set_package
      before_action :set_project

      after_action :verify_authorized
      after_action :supersede_requests, only: [:create]

      def new
        bs_request_action = BsRequestAction.new(target_package: @package, source_project: @project, type: 'submit')
        @bs_request = BsRequest.new(bs_request_actions: [bs_request_action])
        authorize @bs_request, :new?
      end

      # def create
      #   begin
      #     bs_request = BsRequest.new(bs_request_params)
      #     bs_request.save!
      #   rescue BsRequestAction::Errors::DiffError => e
      #     flash[:error] = "Unable to diff sources: #{e.message}"
      #   rescue BsRequestAction::MissingAction => e
      #     flash[:error] = 'Unable to submit, sources are unchanged'
      #   rescue ::Project::UnknownObjectError,
      #          BsRequestAction::UnknownProject,
      #          BsRequestAction::UnknownTargetPackage => e
      #     redirect_back(fallback_location: root_path, error: "Unable to submit (missing target): #{e.message}")
      #     return
      #   rescue APIError, ActiveRecord::RecordInvalid => e
      #     flash[:error] = "Unable to submit: #{e.message}"
      #   rescue ActiveRecord::RecordInvalid => e
      #     flash[:error] = "Unable to submit: #{e.message}"
      #   end

      # if flash[:error]
      #   if bs_request_params[:source_package].blank?
      #     redirect_to(project_show_path(project: project_name))
      #   else
      #     redirect_to(package_show_path(project: project_name, package: package_name))
      #   end
      # end
      # end

      private

      def bs_request_params
        params.require(:bs_request)
          .permit(:description,
                  bs_request_actions_attributes: [:target_package,
                                                  :target_project,
                                                  :source_project,
                                                  :source_package,
                                                  :source_rev])
      end

      def supersede_requests
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
      end
    end
  end
end
