module RedmineCkeditorSetting
  extend ActionView::Helpers
  extend Redmine::I18n


  def self.setting
    Setting[:plugin_redmine_ckeditor] || {}
  end

  def self.default
    ["1", true].include?(setting["default"])
  end

  def self.toolbar_string
    setting["toolbar"] || RedmineCkeditor.default_toolbar
  end

  def self.toolbar
    bars = []
    bar = []
    toolbar_string.split(",").each {|item|
      case item
      when '/'
        bars.push(bar, item)
        bar = []
      when '--'
        bars.push(bar)
        bar = []
      else
        bar.push(item)
      end
    }

    bars.push(bar) unless bar.empty?
    bars
  end

  def self.skin
    setting["skin"] || "moono-lisa"
  end

  def self.ui_color
    setting["ui_color"] || "#f4f4f4"
  end

  def self.enter_mode
    (setting["enter_mode"] || 1).to_i
  end

  def self.shift_enter_mode
    enter_mode == 2 ? 1 : 2
  end

  def self.show_blocks
    (setting["show_blocks"] || 1).to_i == 1
  end

  def self.toolbar_can_collapse
    setting["toolbar_can_collapse"].to_i == 1
  end

  def self.toolbar_location
    setting["toolbar_location"] || "top"
  end

  def self.width
    setting["width"]
  end

  def self.height
    setting["height"] || 400
  end

  # **************************
  # * User mentions settings *
  # **************************
  def self.user_mentions
    setting['user_mentions'].to_i > 0
  end

  def self.user_mentions_triggered_by
    setting['user_mentions_triggered_by'] || 0
  end

  def self.user_mentions_triggered_by_options
    options_for_select(
      trigger_by_options,
      setting['user_mentions_triggered_by'] || 0
    )
  end

  def self.user_mentions_min_chars
    setting['user_mentions_min_chars'] || 3
  end

  def self.user_mentions_max_results
    setting['user_mentions_max_results'] || 10
  end

  def self.user_mentions_action
    setting['user_mentions_action'] || 0
  end

  def self.user_mentions_action_options
    options_for_select(
      user_action_options,
      setting['user_mentions_action'] || 0
    )
  end

  def self.user_mentions_format
    setting['user_mentions_format'] || 0
  end

  def self.user_mentions_format_options
    options_for_select(
      user_format_options,
      setting['user_mentions_format'] || 0
    )
  end

  def self.user_mentions_avatars
    setting['user_mentions_avatars'].to_i > 0
  end

  def self.user_mentions_project_only
    setting['user_mentions_project_only'].to_i > 0
  end

  def self.user_mentions_notifications
    setting['user_mentions_notifications'].to_i > 0
  end

  def self.user_mentions_notify_on
    setting['user_mentions_notify_on'] || 0
  end

  def self.user_mentions_notification_style
    setting['user_mentions_notification_style'] || 'color: red;font-weight: bold'
  end

  def self.user_mentions_notify_on_options
    options_for_select(
      notification_type_options,
      setting['user_mentions_notify_on'] || 0
    )
  end

  def self.user_mentions_notification_subject
    setting['user_mentions_notification_subject'] || l(:ck_notification_default_user_subject)
  end

  def self.user_mentions_notification_msg
    setting['user_mentions_notification_msg'] || l(:ck_notification_default_user_msg)
  end

  # ***************************
  # * Issue mentions settings *
  # ***************************
  def self.issue_mentions
    setting['issue_mentions'].to_i > 0
  end

  def self.issue_mentions_triggered_by
    setting['issue_mentions_triggered_by'] || 1
  end

  def self.issue_mentions_triggered_by_options
    options_for_select(
      trigger_by_options,
      setting['issue_mentions_triggered_by'] || 1
    )
  end

  def self.issue_mentions_min_chars
    setting['issue_mentions_min_chars'] || 3
  end

  def self.issue_mentions_max_results
    setting['issue_mentions_max_results'] || 10
  end

  def self.issue_mentions_format
    setting['issue_mentions_format'] || 0
  end

  def self.issue_mentions_format_options
    options_for_select(
      issue_format_options,
      setting['issue_mentions_format'] || 0
    )
  end

  def self.issue_mentions_project_only
    setting['issue_mentions_project_only'].to_i > 0
  end

  def self.issue_mentions_notifications
    setting['issue_mentions_notifications'].to_i > 0
  end

  def self.issue_mentions_notify_on
    setting['issue_mentions_notify_on'] || 0
  end

  def self.issue_mentions_notification_style
    setting['issue_mentions_notification_style'] || 'color: red;font-weight: bold'
  end

  def self.issue_mentions_notify_on_options
    options_for_select(
      notification_type_options,
      setting['issue_mentions_notify_on'] || 0
    )
  end

  def self.issue_mentions_notification_msg
    setting['issue_mentions_notification_msg'] || l(:ck_notification_default_issue_msg)
  end

  # **************************
  # * Other mentions methods *
  # **************************

  def self.trigger_by_options
    [
      ['@', 0], ['#', 1], ['~', 2], [':', 3], ['!', 4], ['%', 5]
    ]
  end

  def self.user_action_options
    [
      [l(:ck_link_to_user), 0], [l(:ck_mailto_user), 1]
    ]
  end

  def self.user_format_options
    [
      [l(:ck_user_name), 0], [l(:ck_user_login), 1], [l(:ck_user_mail), 2]
    ]
  end

  def self.issue_format_options
    [
      [l(:ck_issue_id), 0], [l(:ck_issue_subject), 1]
    ]
  end

  def self.notification_type_options
    [
      [l(:ck_notify_journal).capitalize, 0],
      [[l(:ck_notify_creation), l(:ck_notify_journal)].to_sentence.capitalize, 1],
      [[l(:ck_notify_creation), l(:ck_notify_update), l(:ck_notify_journal)].to_sentence.capitalize, 2]
    ]
  end
end
