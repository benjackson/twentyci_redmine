class KanbanPane
  def settings
    KanbanPane.settings
  end

  def self.settings
    Setting.plugin_redmine_kanban
  end

  def get_issues(options={})
    nil
  end

  def self.pane_name
    self.to_s.demodulize.gsub(/pane/i, '').downcase
  end

  def self.configured?
    pane = self.pane_name
    (settings['panes'] && settings['panes'][pane] && !settings['panes'][pane]['status'].blank?)
  end

  def self.pane_order
    if pane_order_reversed?
      [:incoming, :finished, :canceled, :testing, :active, :selected, :quick, :backlog]
    else
      [:incoming, :backlog, :quick, :selected, :active, :testing, :finished, :canceled]
    end
  end

  def self.pane_order_reversed?
    user_preference = check_user_preference_for_pane_order

    if user_preference.nil?
      settings.present? &&
        settings['reverse_pane_order'].present? &&
        settings['reverse_pane_order'].to_s == "1"
    else
      # User override
      return user_preference
    end
  end
  
  private

  # Can return:
  # true - yes, reverse
  # false - no, do not reverse
  # nil - no preference
  def self.check_user_preference_for_pane_order
    if User.current.logged? && User.current.pref.present?
      User.current.pref.kanban_reverse_pane_order
    end
  end

  def missing_settings(pane, options={})
    skip_status = options.delete(:skip_status)

    settings.blank? ||
      settings['panes'].blank? ||
      settings['panes'][pane].blank? ||
      settings['panes'][pane]['limit'].blank? ||
      (settings['panes'][pane]['status'].blank? && !skip_status)
  end

  # Sort and group a set of issues based on IssuePriority#position
  def group_by_priority_position(issues)
    return issues.group_by {|issue|
      issue.priority
    }.sort {|a,b|
      a[0].position <=> b[0].position
    }
  end

  def conditions_from_for_options(for_option)
    for_conditions = []
    if for_option.include?(:author)
      for_conditions << " #{Issue.table_name}.author_id = :user"
    end

    if for_option.include?(:watcher)
      for_conditions << " #{Watcher.table_name}.user_id = :user"
    end

    if for_option.include?(:assigned_to)
      for_conditions << "#{Issue.table_name}.assigned_to_id = :user"
    end

    for_conditions
  end

  def merge_for_option_conditions(conditions, for_option)
    if conditions_from_for_options(for_option).present?
      conditions << " AND ("
      conditions << conditions_from_for_options(for_option).join(" OR ")
      conditions << " ) "
    end

    conditions
  end

end
