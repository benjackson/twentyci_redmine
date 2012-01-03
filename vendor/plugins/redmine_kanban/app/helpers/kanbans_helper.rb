module KanbansHelper
  def name_to_css(name)
    name.gsub(' ','-').downcase
  end

  def jquery_dialog_div(title=:field_issue)
    "<div id='dialog-window' title='#{ l(title) }'></div>"
  end

  def render_pane_to_js(pane, user=nil)
    if Kanban.valid_panes.include?(pane)
      return render_to_string(:partial => pane, :locals => {:user => user })
    else
      ''
    end
  end

  # Returns the CSS class for jQuery to hook into.  Current users are
  # allowed to Drag and Drop items into their own list, but not other
  # people's lists
  def allowed_to_assign_staffed_issue_to(user)
    if allowed_to_manage? || User.current == user
      'allowed'
    else
      ''
    end
  end

  def over_pane_limit?(limit, counter)
    if !counter.nil? && !limit.nil? && counter.to_i >= limit.to_i # 0 based counter
      return 'over-limit'
    else
      return ''
    end
  end

  # Was the last journal with a note created by someone other than the
  # assigned to user?
  def updated_note_on_issue?(issue)
    if issue && issue.journals.present?
      last_journal_with_note = issue.journals.select {|journal| journal.notes.present?}.last
      if last_journal_with_note && issue.assigned_to_id != last_journal_with_note.user_id
        last_journal_with_note
      else
        return false
      end
      
    end
  end

  def issue_updated_note_icon(issue)
    if last_journal = updated_note_on_issue?(issue)
      image_tag('comment.png', :class => "updated-note issue-show-popup issue-id-#{h(issue.id)}", :id => "issue-#{h(issue.id)}", :alt => l(:kanban_text_updated_issue), :title => h(last_journal.notes))
    end
  end

  def kanban_issue_css_classes(issue)
    css = 'kanban-issue ' + issue.css_classes
    if User.current.logged? && !issue.assigned_to_id.nil? && issue.assigned_to_id != User.current.id
      css << ' assigned-to-other'
    end
    css << ' issue-behind-schedule' if issue.behind_schedule?
    css << ' issue-overdue' if issue.overdue?
    css << ' parent-issue' if issue.root? && issue.children.count > 0
    css
  end

  def issue_icon_link(issue)
    if Setting.gravatar_enabled? && issue.assigned_to
      img = avatar(issue.assigned_to, {
                     :class => 'gravatar icon-gravatar',
                     :size => 10,
                     :title => l(:field_assigned_to) + ": " + issue.assigned_to.name
                   })
      link_to(img, :controller => 'issues', :action => 'show', :id => issue)
    else
      link_to(image_tag('ticket.png', :style => 'float:left;'), :controller => 'issues', :action => 'show', :id => issue)
    end
  end

  def column_configured?(column)
    case column
    when :incoming
      KanbanPane::IncomingPane.configured?
    when :backlog
      KanbanPane::BacklogPane.configured?
    when :selected
      KanbanPane::QuickPane.configured? || KanbanPane::SelectedPane.configured?
    when :staffed
      true # always
    end
  end

  # Calculates the width of the column.  Max of 96 since they need
  # some extra for the borders.
  def column_width(column)
    # weights of the columns
    column_ratios = {
      :incoming => 1,
      :backlog => 1,
      :selected => 1,
      :staffed => 4
    }
    return 0.0 if column == :incoming && !column_configured?(:incoming)
    return 0.0 if column == :backlog && !column_configured?(:backlog)
    return 0.0 if column == :selected && !column_configured?(:selected)
    
    visible = 0
    visible += column_ratios[:incoming] if column_configured?(:incoming)
    visible += column_ratios[:backlog] if column_configured?(:backlog)
    visible += column_ratios[:selected] if column_configured?(:selected)
    visible += column_ratios[:staffed] if column_configured?(:staffed)
    
    return ((column_ratios[column].to_f / visible) * 96).round(2)
  end

  def my_kanban_column_width(column)
    column_ratios = {
      :project => 1,
      :testing => 1,
      :active => 1,
      :selected => 1,
      :backlog => 1
    }

    # Vertical column
    if column == :incoming
      return (KanbanPane::IncomingPane.configured? ? 100.0 : 0.0)
    end

    # Inside of Project, max width
    if column == :finished || column == :canceled
      return 100.0
    end

    return 0.0 if column == :active && !KanbanPane::ActivePane.configured?
    return 0.0 if column == :testing && !KanbanPane::TestingPane.configured?
    return 0.0 if column == :selected && !KanbanPane::SelectedPane.configured?
    return 0.0 if column == :backlog && !KanbanPane::BacklogPane.configured?

    visible = 0
    visible += column_ratios[:project]
    visible += column_ratios[:active] if KanbanPane::ActivePane.configured?
    visible += column_ratios[:testing] if KanbanPane::TestingPane.configured?
    visible += column_ratios[:selected] if KanbanPane::SelectedPane.configured?
    visible += column_ratios[:backlog] if KanbanPane::BacklogPane.configured?

    return ((column_ratios[column].to_f / visible) * 96).round(2)
  end

  # Calculates the width of the column.  Max of 96 since they need
  # some extra for the borders.
  def staffed_column_width(column)
    # weights of the columns
    column_ratios = {
      :user => 1,
      :active => 2,
      :testing => 2,
      :finished => 2,
      :canceled => 2
    }
    return 0.0 if column == :active && !KanbanPane::ActivePane.configured?
    return 0.0 if column == :testing && !KanbanPane::TestingPane.configured?
    return 0.0 if column == :finished && !KanbanPane::FinishedPane.configured?
    return 0.0 if column == :canceled && !KanbanPane::CanceledPane.configured?

    visible = 0
    visible += column_ratios[:user]
    visible += column_ratios[:active] if KanbanPane::ActivePane.configured?
    visible += column_ratios[:testing] if KanbanPane::TestingPane.configured?
    visible += column_ratios[:finished] if KanbanPane::FinishedPane.configured?
    visible += column_ratios[:canceled] if KanbanPane::CanceledPane.configured?
    
    return ((column_ratios[column].to_f / visible) * 96).round(2)
  end
    
  def issue_url(issue)
    url_for(:controller => 'issues', :action => 'show', :id => issue)
  end

  def showing_current_user_kanban?
    @user == User.current
  end

  # Renders the title for the "Incoming" project.  It can be linked as:
  # * New Issue jQuery dialog (user has permission to add issues)
  # * Link to the url configured in the plugin (plugin is configured with a url)
  # * No link at all
  def incoming_title
    

    if Setting.plugin_redmine_kanban['panes'].present? &&
        Setting.plugin_redmine_kanban['panes']['incoming'].present? &&
        Setting.plugin_redmine_kanban['panes']['incoming']['url'].present?

      href_url = Setting.plugin_redmine_kanban['panes']['incoming']['url']
      incoming_project = extract_project_from_url(href_url)
      link_name = incoming_project.present? ? incoming_project.name : l(:kanban_text_incoming)
    else
      href_url = ''
      link_name = l(:kanban_text_incoming)
    end
    
    if User.current.allowed_to?(:add_issues, nil, :global => true)
       link_to(link_name, href_url, :class => 'new-issue-dialog')
    elsif href_url.present?
      link_to(link_name, href_url)
    else
      link_name
    end
  end

  # Given a url, extract the project record from it.
  # Will return nil if the url isn't a link to a project or the url can't be
  # recognized
  def extract_project_from_url(url)
    project = nil
    
    link_path = url.
      sub(request.host, ''). # Remove host
      sub(/https?:\/\//,''). # Protocol
      sub(/\?.*/,'') # Query string
    begin
      route = ActionController::Routing::Routes.recognize_path(link_path, :method => :get)
      if route[:controller] == 'projects' && route[:id]
        project = Project.find(route[:id])
      end
    rescue ActionController::RoutingError # Parse failed, not a route
    end
  end

  def export_i18n_for_javascript
    strings = {
      'kanban_text_error_saving_issue' => l(:kanban_text_error_saving_issue),
      'kanban_text_issue_created_reload_to_see' => l(:kanban_text_issue_created_reload_to_see),
      'kanban_text_issue_updated_reload_to_see' => l(:kanban_text_issue_updated_reload_to_see),
      'kanban_text_notice_reload' => l(:kanban_text_notice_reload),
      'kanban_text_watch_and_cancel_hint' => l(:kanban_text_watch_and_cancel_hint),
      'kanban_text_issue_watched_reload_to_see' => l(:kanban_text_issue_watched_reload_to_see)
    }

    javascript_tag("var i18n = #{strings.to_json}")
  end
  
  def viewed_user
    return @user if @user.present?
    return User.current
  end

  def use_simple_issue_popup_form?
    # TODO: Hate how Settings is stored...
    @settings['simple_issue_popup_form'] && (
                                       @settings['simple_issue_popup_form'] == '1' ||
                                       @settings['simple_issue_popup_form'] == 1 ||
                                       @settings['simple_issue_popup_form'] == true
                                       )
  end

  # Load remote RJS/HTML data from url into dom_id
  def kanban_remote_data(url, dom_id)
    javascript_tag("Kanban.remoteData('#{url}', '#{dom_id}');") +
      content_tag(:span, l(:label_loading), :class => 'loading')
  end

  # Returns a list of pane names in the configured order.
  #
  # @param hash options Method options
  # @option options Array :only Filter the panes to only include these ones
  def ordered_panes(options={})
    only = options[:only] || []
    if only.present?
      KanbanPane.pane_order.select {|pane| only.include?(pane) }
    else
      KanbanPane.pane_order
    end
  end
  
  class UserKanbanDivHelper < BlockHelpers::Base
    include ERB::Util

    def initialize(options={})
      @column = options[:column]
      @user = options[:user]
      @project_id = options[:project_id]
    end

    def issues(issues)
      if issues.compact.empty? || issues.flatten.compact.empty?
        render :partial => 'kanbans/empty_issue'
      else
        render(:partial => 'kanbans/issue',
               :collection => issues.flatten,
               :locals => { :limit => Setting['plugin_redmine_kanban']["panes"][@column.to_s]["limit"].to_i })
      end
    end

    def display(body)
      content_tag(:div,
                  content_tag(:ol,
                              body,
                              :id => "#{@column}-issues-user-#{h(@user.id)}-project-#{h(@project_id)}", :class => "#{@column}-issues"),
                  :id => "#{@column}-#{h(@user.id)}-project-#{h(@project_id)}", :class => "pane equal-column #{@column} user-#{h(@user.id)}", :style => "width: #{ helper.my_kanban_column_width(@column)}%")
    end
    
  end

  class KanbanContextualMenu < BlockHelpers::Base

    def initialize(options={})
      @kanban = options[:kanban]
      @user = options[:user]
    end

    def color_help
      link_to_function(l(:kanban_text_color_help), "$('color-help').toggle();", :class => 'icon icon-info')
    end

    def kanban_board
      if User.current.allowed_to?(:view_kanban, nil, :global => true)
        link_to(l(:text_kanban_board), kanban_url, :class => 'icon icon-stats')
      end
    end

    def my_kanban_requests
      link_to(l(:text_my_kanban_requests_title), kanban_user_kanban_path(:id => User.current.id), :class => 'icon icon-user')
    end

    def assigned_requests
      link_to(l(:text_assigned_kanban_title), kanban_assigned_kanban_path(:id => User.current.id), :class => 'icon icon-user')
    end

    def new_issue
      if User.current.allowed_to?(:add_issues, nil, :global => true)

        if Setting.plugin_redmine_kanban['panes'].present? &&
            Setting.plugin_redmine_kanban['panes']['incoming'].present? &&
            Setting.plugin_redmine_kanban['panes']['incoming']['url'].present?

          incoming_url = Setting.plugin_redmine_kanban['panes']['incoming']['url']
          incoming_project = extract_project_from_url(incoming_url)
          link_name = incoming_project.present? ? incoming_project.name : l(:label_issue_new)
        else
          link_name = l(:label_issue_new)
        end
        
         link_to_function(link_name, "void(0)", :class => 'new-issue-dialog icon icon-issue')
      end
    end

    def sync_kanban
      if User.current.allowed_to?(:edit_kanban, nil, :global => true)
        link_to(l(:kanban_text_sync), sync_kanban_url, :method => :put, :class => 'icon icon-reload')
      end
    end

    # @param [Hash] options
    # @option options [String] :url URL that the user switch form should post to
    # @option options [String] :label Text to use for the Switch User label (i18n'd already)
    # @option options [String] :users Users to allow switching to. Defaults to all active Users
    def user_switch(options={})
      url = options[:url]
      label = options[:label] || l(:label_user_switch)
      users = options[:users] || User.active
      
      if kanban_settings["management_group"] && User.current.group_ids.include?(kanban_settings["management_group"].to_i)
        render :partial => 'kanbans/user_switch', :locals => {:url => url, :label => label, :users => users.sort}
      end
    end

    def display(body)
      content = call_hook(:view_user_kanbans_show_contextual_top, :user => @user, :kanban => @kanban).to_s
      content += body
      content += call_hook(:view_user_kanbans_show_contextual_bottom, :user => @user, :kanban => @kanban).to_s
      
      content_tag(:div,
                  content,
                  :class => "contextual")
    end
  end
  
end
