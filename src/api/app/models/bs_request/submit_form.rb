class BsRequest::SubmitForm
  include ActiveModel::Model

  attr_reader :bs_request, :revision

  def initialize(bs_request, revision)
    @bs_request = bs_request
    @revision = revision
  end

  def update!(bs_request_params)
    target_project_name = params[:targetproject].try(:strip)
    package_name = params[:package].strip
    project_name = params[:project].strip

    if params[:target_package].blank?
      target_package_name = package_name
    else
      target_package_name = params[:target_package].try(:strip)
    end

    if target_project_name.blank?
      flash[:error] = 'Please provide a target for the submit request'
      redirect_to action: :show, project: project_name, package: package_name
      return
    end

  end
end
