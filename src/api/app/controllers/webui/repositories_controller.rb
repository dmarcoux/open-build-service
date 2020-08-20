class Webui::RepositoriesController < Webui::WebuiController
  before_action :set_project
  before_action :set_repository, only: [:state]
  before_action :set_architectures, only: [:index, :change_flag]
  before_action :find_repository_parent, only: [:index, :change_flag]
  before_action :check_ajax, only: :change_flag
  after_action :verify_authorized, except: [:index, :distributions, :state]

  # GET /repositories/:project(/:package)
  # Compatibility routes
  # GET package/repositories/:project/:package
  # GET project/repositories/:project
  def index
    @available_architectures = Architecture.available
    @repositories = @project.repositories.preload({ path_elements: { link: :project } }, :architectures)
    @repositories = @repositories.includes(:download_repositories)
    @user_can_modify = @package.present? ? policy(@package).update? : policy(@project).update?

    @flags = {}
    [:build, :debuginfo, :publish, :useforbuild].each do |flag_type|
      @flags[flag_type] = Flag::SpecifiedFlags.new(@main_object, flag_type)
    end
  end

  # GET project/add_repository/:project
  def new
    authorize @project, :update?
  end

  # GET project/add_repository_from_default_list/:project
  def distributions
    @distributions = {}
    Distribution.all_including_remotes.each do |dis|
      @distributions[dis['vendor']] ||= []
      @distributions[dis['vendor']] << dis
    end

    return unless @distributions.empty?
    redirect_to(action: 'new', project: @project) && return unless User.admin_session?

    redirect_to(new_interconnect_path,
                alert: 'There are no distributions configured. Maybe you want to connect to one of the public OBS instances?')
  end

  # POST project/save_repository
  def create
    authorize @project, :update?
    repository = @project.repositories.find_or_initialize_by(name: params[:repository])
    if params[:target_repo]
      target_repository = Repository.find_by_project_and_name(params[:target_project], params[:target_repo])
      repository.path_elements.find_or_initialize_by(link: target_repository)
    end

    params[:architectures] ||= []
    params[:architectures].each do |architecture|
      repository.repository_architectures.find_or_initialize_by(architecture: Architecture.find_by(name: architecture))
    end

    if repository.save
      @project.store(comment: "Added #{repository.name} repository")
      flash[:success] = "Successfully added repository '#{repository.name}'"
      respond_to do |format|
        format.html { redirect_to(action: :index, project: @project) }
        format.js
      end
    else
      flash[:error] = "Can not add repository: #{repository.errors.full_messages.to_sentence}"
      respond_to do |format|
        format.html { redirect_back(fallback_location: root_path) }
        format.js
      end
    end
  end

  # POST project/update_target/:project
  def update
    authorize @project, :update?
    repo = @project.repositories.where(name: params[:repo]).first
    archs = []
    archs = params[:arch].keys.map { |arch| Architecture.find_by_name(arch) } if params[:arch]
    repo.architectures = archs
    repo.save
    @project.store(comment: "Modified #{repo.name} repository")

    # Merge project repo's arch list with currently available arches from API. This needed as you want
    # to keep currently non-working arches in the project meta.
    @repository_arch_hash = {}
    Architecture.available.each { |arch| @repository_arch_hash[arch.name] = false }
    repo.architectures.each { |arch| @repository_arch_hash[arch.name] = true }
    redirect_to({ action: :index }, success: 'Successfully updated repository')
  end

  # DELETE /project/remove_target
  def destroy
    authorize @project, :update?
    repository = @project.repositories.find_by(name: params[:target])
    result = repository && @project.repositories.delete(repository)
    if @project.valid? && result
      @project.store(comment: "Removed #{repository.name} repository")
      respond_to do |format|
        flash[:success] = "Successfully removed repository '#{repository.name}'"
        format.html { redirect_to(action: :index, project: @project) }
        format.js
      end
    else
      msg = "Failed to remove repository: #{@project.errors.full_messages.to_sentence}"
      msg << 'Repository not found.' if @project.valid? && !result
      respond_to do |format|
        flash[:error] = msg
        format.html { redirect_back(fallback_location: root_path) }
        format.js
      end
    end
  end

  # GET project/repository_state/:project/:repository
  def state
    @state_presenter = Repositories::StatePresenter.new(@project, @repository, @configuration)
  end

  # POST /project/create_dod_repository
  def create_dod_repository
    download_on_demand = DownloadRepository.new(arch: params[:arch],
                                                url: params[:url], repotype: params[:repotype])
    authorize download_on_demand, :create?

    @error = "Repository with name '#{params[:name]}' already exists." if Repository.find_by_name(params[:name])

    begin
      ActiveRecord::Base.transaction do
        @new_repository = @project.repositories.create!(name: params[:name])
        @new_repository.repository_architectures.create!(architecture: Architecture.find_by(name: params[:arch]), position: 1)
        @new_repository.download_repositories.create!(arch: params[:arch], url: params[:url], repotype: params[:repotype])
        @project.store
      end
    rescue ::Timeout::Error, ActiveRecord::RecordInvalid => e
      @error = "Couldn't add repository: #{e.message}"
    end

    if @error
      flash[:error] = @error
    else
      flash[:success] = "Repository '#{params[:name]}' was successfully created."
    end
    redirect_to action: 'index', project: @project
  end

  # POST project/create_image_repository
  def create_image_repository
    authorize @project, :update?
    repository = @project.repositories.new(name: 'images')

    if repository.save
      Architecture.available.each do |architecture|
        repository.repository_architectures.create(architecture: architecture)
      end

      @project.prepend_kiwi_config
      @project.store

      flash[:success] = 'Successfully added image repository'
      respond_to do |format|
        format.html { redirect_to(action: :index, project: @project) }
        format.js { render 'create' }
      end
    else
      flash[:error] = "Can not add image repository: #{repository.errors.full_messages.to_sentence}"
      respond_to do |format|
        format.html { redirect_back(fallback_location: root_path) }
        format.js { render 'create' }
      end
    end
  end

  # POST flag/:project(/:package)
  def change_flag
    required_parameters :flag, :command
    authorize @main_object, :update?

    flag_type = params[:flag]
    follow_change_flag_command(flag_type)

    locals = { user_can_modify: true, project: @project, package: params[:package], architectures: @architectures }
    locals[:flags] = Flag::SpecifiedFlags.new(@main_object, flag_type)
    locals[:table_id] = 'flag_table_' + flag_type

    render partial: 'webui/shared/repositories_flag_table', locals: locals
  end

  private

  def follow_change_flag_command(flag_type)
    architecture = Architecture.from_cache!(params[:architecture]) if params[:architecture]

    case params[:command]
    when 'remove'
      @main_object.flags.of_type(flag_type).where(repo: params[:repository], architecture: architecture).delete_all
    when /^set-(?<status>disable|enable)$/
      flag = @main_object.flags.find_or_create_by(flag: flag_type, repo: params[:repository], architecture: architecture)
      flag.update(status: $LAST_MATCH_INFO['status'])
    end
    @main_object.store
  end

  def set_architectures
    @architectures = Architecture.where(id: @project.repository_architectures.select(:architecture_id)).order(:name)
  end

  def set_repository
    @repository = @project.repositories.find_by!(name: params[:repository])
  end

  def find_repository_parent
    if params[:package]
      # FIXME: Handle APIError different, this is just c&p from packages_controller
      begin
        @main_object = @package = Package.get_by_project_and_name(@project.to_param, params[:package], use_source: false, follow_project_links: true)
      rescue APIError
        raise ActiveRecord::RecordNotFound, 'Not Found'
      end
    else
      @main_object = @project
    end
  end
end
