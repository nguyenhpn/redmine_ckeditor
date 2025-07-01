module RedmineCkeditorHelper
  include ActionView::Helpers::UrlHelper
  include Rails.application.routes.url_helpers

  # Includes ck editor javascripts on the page where they are needed
  # @return [String] - string which contains HTML to include necessary javascript files
  def ckeditor_javascripts
    root = RedmineCkeditor.assets_root
    plugin_script = RedmineCkeditor.plugins.map {|name|
      "CKEDITOR.plugins.addExternal('#{name}', '#{root}/ckeditor-contrib/plugins/#{name}/');"
    }.join

    ckeditor_script = <<-EOT
      #{plugin_script}

      CKEDITOR.on("instanceReady", function(event) {
        var editor = event.editor;
        var textarea = document.getElementById(editor.name);
        editor.on("change", function() {
          textarea.value = editor.getSnapshot();
        });
      });

      $(window).on("beforeunload", function() {
        for (var id in CKEDITOR.instances) {
          if (CKEDITOR.instances[id].checkDirty()) {
            return #{l(:text_warn_on_leaving_unsaved).inspect};
          }
        }
      });
      $(document).on("submit", "form", function() {
        for (var id in CKEDITOR.instances) {
          CKEDITOR.instances[id].resetDirty();
        }
      });
    EOT

    javascript_tag(ckeditor_data_for_javascript).html_safe +
    javascript_tag("CKEDITOR_BASEPATH = '#{root}/ckeditor/';").html_safe +
    javascript_include_tag("application", :plugin => "redmine_ckeditor").html_safe +
    javascript_tag(ckeditor_script).html_safe
  end

  # Assigns ckeditor mention plugin options to the window.CKEditor global variable from where it is
  # later used while CKEditor is being configured
  # @return [String] - string containing JS script tag with assignment of mention config to the
  #                    global variable
  def ckeditor_data_for_javascript
    mentions_config = []
    mentions_config << user_mentions_options(@project) if RedmineCkeditorSetting.user_mentions
    mentions_config << issue_mentions_options(@project) if RedmineCkeditorSetting.issue_mentions

    script = <<-EOT
      window.CKEditor ||= {};
      window.CKEditor.mentionsConfig = #{mentions_config.to_json};
    EOT

    script
  end

  # Returns options object for user mentions based on the plugin settings
  # @param [Project] project - AR Project object with the current project
  # @return [Hash] - ckeditor mention plugin config object with keys :feed (url of endpoint
  #                  delivering suggestions in json), :marker (char, which triggers the mention
  #                  plugin), :minChars (min chars to trigger the mention plugin), :itemTamplate
  #                  (html template of the suggestion item), :outputTemplate (html template of the
  #                  resulting mention)
  def user_mentions_options(project=nil)
    # Feed url
    url_params = {
      name: '{encodedQuery}'
    }
    url_params[:project_id] = project.id if project
    url_patams_string = url_params.map { |k, v| "#{k}=#{v}" }.join('&')
    feed_url = "#{ckeditor_users_path}?#{url_patams_string}"

    marker = RedmineCkeditorSetting.trigger_by_options.find do |option|
      option.second == RedmineCkeditorSetting.user_mentions_triggered_by.to_i
    end.first

    {
      feed: feed_url,
      marker: marker,
      minChars: RedmineCkeditorSetting.user_mentions_min_chars,
      itemTemplate: user_item_template,
      outputTemplate: user_output_template
    }
  end

  # Returns string with html template of one user suggestion item used by the ckeditor mentions
  # plugin
  # @return [String] - string with html <li> tag, which contains html of suggestion item with
  #                    placeholders in {} parentheses, which are replaced by the data delivered from
  #                    the server
  def user_item_template
    inner_html = ''
    inner_html += content_tag(
      'img',
      '',
      class: '{img_class}',
      height: '{img_size}',
      width: '{img_size}',
      title: '{img_title}',
      src: '{img_src}',
      srcset: '{img_srcset}'
    ) if RedmineCkeditorSetting.user_mentions_avatars

    inner_html += content_tag('span', '{name}')
    "<li class=\"mention-user-item\" data-id=\"{id}\">#{inner_html}</li>"
  end

  # Returns string with html template of one user resulting mention item used by the ckeditor
  # mentions plugin
  # @return [String] - string with html link with placeholders, which are replaced by the data
  #                    delivered from the server
  def user_output_template
    if RedmineCkeditorSetting.user_mentions_action.to_i.zero?
      link_to('{name}', '{url}', class: "user-mention-link-{id}")
    else
      link_to('{name}', 'mailto:{url}', class: "user-mention-link-{id}")
    end
  end

  # Returns options object for issue mentions based on the plugin settings
  # @param [Project] project - AR Project object with the current project
  # @return [Hash] - ckeditor mention plugin config object with keys :feed (url of endpoint
  #                  delivering suggestions in json), :marker (char, which triggers the mention
  #                  plugin), :minChars (min chars to trigger the mention plugin), :itemTamplate
  #                  (html template of the suggestion item), :outputTemplate (html template of the
  #                  resulting mention)
  def issue_mentions_options(project=nil)
    # Feed url
    url_params = {
      name: '{encodedQuery}'
    }
    url_params[:project_id] = project.id if project
    url_patams_string = url_params.map { |k, v| "#{k}=#{v}" }.join('&')
    feed_url = "#{ckeditor_issues_path}?#{url_patams_string}"

    marker = RedmineCkeditorSetting.trigger_by_options.find do |option|
      option.second == RedmineCkeditorSetting.issue_mentions_triggered_by.to_i
    end.first

    {
      feed: feed_url,
      marker: marker,
      minChars: RedmineCkeditorSetting.issue_mentions_min_chars,
      itemTemplate: issue_item_template,
      outputTemplate: issue_output_template
    }
  end

  # Returns string with html template of one issue suggestion item used by the ckeditor mentions
  # plugin
  # @return [String] - string with html <li> tag, which contains html of suggestion item with
  #                    placeholders in {} parentheses, which are replaced by the data delivered from
  #                    the server
  def issue_item_template
    inner_html = content_tag('div', '{sug_id}') + content_tag('div', '{sug_name}')
    "<li class=\"mention-issue-item\" data-id=\"{id}\">#{inner_html}</li>"
  end

  # Returns string with html template of one issue resulting mention item used by the ckeditor
  # mentions plugin
  # @return [String] - string with html link with placeholders, which are replaced by the data
  #                    delivered from the server
  def issue_output_template
    link_to('{name}', '{url}', class: "issue-mention-link-{id}")
  end

  # Returns AR Relation of users with found users based on the given search string. First name, last
  # name and login is used for search.
  # @param [String] search_string - part of first or last name or login of user
  # @param [Project] project - current project or nil, which may narrow down the search
  # @return [ActiveRecord::Relation<User>] - AR relation of found users
  def user_suggestions_query(search_string, project=nil)
    users = User.arel_table
    members = Member.arel_table
    projects = Project.arel_table
    email_addresses = EmailAddress.arel_table

    scope = RedmineCkeditorSetting.user_mentions_format.to_i > 1 ? User.joins(:email_address) : User
    scope = scope.where.not(lastname: 'Anonymous')

    members_join_condition =
      users[:id].eq(members[:user_id])
    members_join =
      users.join(members, Arel::Nodes::OuterJoin).on(members_join_condition).join_sources

    projects_condition =
      projects[:id].eq(members[:project_id])
    projects_join =
      members.join(projects, Arel::Nodes::OuterJoin).on(projects_condition).join_sources

    # Search condition
    scope = if search_string.present? && RedmineCkeditorSetting.user_mentions_format.to_i.zero?
        scope.where(
          users[:firstname].matches("%#{search_string}%")
          .or(users[:lastname].matches("%#{search_string}%"))
        )
      elsif search_string.present? && RedmineCkeditorSetting.user_mentions_format.to_i == 1
        scope.where(users[:login].matches("%#{search_string}%"))
      elsif search_string.present?
        scope.where(email_addresses[:address].matches("%#{search_string}%"))
      else
        scope
      end

    scope = if project.present? && RedmineCkeditorSetting.user_mentions_project_only
      scope = scope.joins(members_join, projects_join).where(projects[:id].eq(project.id))
    else
      scope
    end

    scope.limit(RedmineCkeditorSetting.user_mentions_max_results)
  end

  # Prepares json data in the format suitable for metions plugin suggestions
  # @param [ActiveRecord::Relation<User>] users - AR Relation of users to convert into suggestions
  #                                               json data
  # @return [Hash] -
  def prepare_user_suggestions(users)
    users.map do |user|
      user_mail = user.mail

      url = if RedmineCkeditorSetting.user_mentions_action.to_i.zero?
          user_url(user.id)
        else
          user_mail ? user_mail : '#'
        end

      av_data = if RedmineCkeditorSetting.user_mentions_avatars
          avatar_data(user, size: 24)
        else
          {}
        end

      name = if RedmineCkeditorSetting.user_mentions_format.to_i.zero?
          user.name
        elsif RedmineCkeditorSetting.user_mentions_format.to_i == 1
          user.login
        else
          user_mail ? user_mail : user.name
        end

      { id: user.id, name: name, url: url }.merge(av_data)
    end
  end

  # Returns AR Relation of issues with found issues based on the given search string. Issue subject
  # and id are used for search.
  # @param [String] search_string - part of id or subject
  # @param [Project] project - current project or nil, which may narrow down the search
  # @return [ActiveRecord::Relation<Issue>] - AR relation of found issues
  def issue_suggestions_query(search_string, project=nil)
    issues = Issue.arel_table
    scope = Issue

    scope = if search_string.present?
        subject_condition = issues[:subject].matches("%#{search_string}%")
        id_as_string = if ActiveRecord::Base.connection.adapter_name.downcase.include?('mysql')
            Arel::Nodes::SqlLiteral.new("CAST(#{issues[:id].name} AS CHAR)")
          else
            Arel::Nodes::SqlLiteral.new("CAST(#{issues[:id].name} AS VARCHAR)")
          end
        id_condition = id_as_string.matches("%#{search_string}%")
        scope.where(subject_condition.or(id_condition))
      else
        scope
      end

    scope = if project.present? && RedmineCkeditorSetting.issue_mentions_project_only
        scope = scope.where(project_id: project.id)
      else
        scope
      end

    scope.limit(RedmineCkeditorSetting.issue_mentions_max_results)
  end

  # Prepares json data in the format suitable for metions plugin suggestions
  # @param [ActiveRecord::Relation<Issue>] issues - AR Relation of issues to convert into suggestions
  #                                                 json data
  # @return [Hash] -
  def prepare_issue_suggestions(issues)
    marker = RedmineCkeditorSetting.trigger_by_options.find do |option|
      option.second == RedmineCkeditorSetting.issue_mentions_triggered_by.to_i
    end.first

    issues.map do |issue|
      url = issue_url(issue.id)

      subject = if issue.subject.length > 40
        issue.subject[0, 37] + '...'
      else
        issue.subject
      end
      sug_id = "##{issue.id}"
      sug_name = subject

      name = ''
      if RedmineCkeditorSetting.issue_mentions_format.to_i.zero?
        name = issue.id.to_s
        name = marker == '#' ? name : "##{name}"
      else
        name = marker == '#' ? sug_name[1..-1] : sug_name
      end

      { id: issue.id, sug_id: sug_id, sug_name: sug_name, name: name, url: url }
    end
  end

  # Returns data of avatar, which will be shown in the mentions menu
  # @param [User] user - AR User object of user for who we want to show the avatar
  # @param [Hash] options - further options
  # @option options [Integer] :size - size of the avater. This will be used to set height and eidth
  #                                   attributes of the avatar's img tag
  # @return [Hash] - hash with keys: :img_class (css class of the img), :img_title (title attribute
  #                  of the img), :img_size (height and width of the img), :img_src (url to image),
  #                  :img_srcset (srcset attribute value of the img)
  def avatar_data(user, options={})
    data = avatar_local_data(user, options)
    return data if data.present?

    avatar_redmine_data(user, options)
  end

  # Returns data for avatar, which is in a local attached file (or nil, if such a file is not found)
  # @param [User] user - AR User object of user for who we want to show the avatar
  # @param [Hash] options - further options
  # @option options [Integer] :size - size of the avater. This will be used to set height and eidth
  #                                   attributes of the avatar's img tag
  # @return [Hash] - hash with keys: :img_class (css class of the img), :img_title (title attribute
  #                  of the img), :img_size (height and width of the img), :img_src (url to image),
  #                  :img_srcset (srcset attribute value of the img)
  def avatar_local_data(user, options={})
    if user.is_a?(User)
      av = user.attachments.find_by_description 'avatar' if user.respond_to?(:attachments)
      if av then
        image_url = url_for :only_path => true, :controller => 'account', :action => 'get_avatar', :id => user
        options[:size] = "24" unless options[:size]
        title = "#{user.name}"
        return { img_class: 'gravatar', img_title: title, img_size: options[:size], img_src: image_url, img_srcset: '' }
      end
    end
    nil
  end

  # Returns data for avatar, which is not in a local attached file - i.e. either gravatar or no
  # avatar at all, because Redmine supports only gravatar avatars
  # @param [User] user - AR User object of user for who we want to show the avatar
  # @param [Hash] options - further options
  # @option options [Integer] :size - size of the avater. This will be used to set height and eidth
  #                                   attributes of the avatar's img tag
  # @return [Hash] - hash with keys: :img_class (css class of the img), :img_title (title attribute
  #                  of the img), :img_size (height and width of the img), :img_src (url to image),
  #                  :img_srcset (srcset attribute value of the img)
  def avatar_redmine_data(user, options={})
    options[:default] = Setting.gravatar_default
    img_class = 'gravatar'
    img_class += " #{options[:class]}" if options[:class]

    result = {
      img_class: img_class,
      img_title: '',
      img_size: options[:size] || GravatarHelper::DEFAULT_OPTIONS[:size],
      img_srcset: ''
    }

    anonymous_data = result.merge(img_src: image_path('anonymous.png'))
    group_data = result.merge(img_src: image_path('group.png'))

    return anonymous_data if user.is_a?(AnonymousUser)
    return group_data if user.is_a?(Group)

    if Setting.gravatar_enabled?
      email = nil
      if user.respond_to?(:mail)
        email = user.mail
        options[:title] = user.name unless options[:title]
      elsif user.to_s =~ %r{<(.+?)>}
        email = $1
      end

      if email.present?
        srcset = "#{gravatar_url(email, options.merge(size: options[:size].to_i * 2))} 2x"
        src = h(gravatar_url(email, options))
        result.merge(img_src: src, img_srcset: srcset)
      else
        anonymous_data
      end
    else
      anonymous_data
    end
  end

  # Notifies after issue mention by creating new journal message to the mentioned issue
  # @param [Symbol] notification_type - either :ck_notify_journal (if mention is in the new journal
  #   message), :ck_notify_creation (if mention is in the new issue description) or
  #   :ck_notify_update (if mention is in the updated issue description)
  # @param [Issue] issue - AR Issue object of the issue, which description or journal contains mention
  # @param [String] text - text in which mention is contained (issue description or journal)
  def notify_issue(notification_type, issue, text)
    if notification_type == :ck_notify_update
      orig_issue = Issue.find_by(id: issue.id)
      return if orig_issue && orig_issue.description == text
    end

    matches = text.scan(/issue-mention-link-\d+/)

    matches.uniq.each do |match|
      notified_id = match.split('-').last.to_i
      next if notified_id == issue.id

      notified_issue = Issue.find_by(id: notified_id)
      next unless notified_issue

      msg = notification_issue_msg(notification_type, notified_id, issue.id, issue.subject, text)
      journal = notified_issue.journals.build

      # Set do_not_notify flag to true, so there will be no mention notification for this journal
      journal.do_not_notify = true

      # Set the attributes of the journal
      journal.user = User.current
      journal.notes = msg
      journal.save
    end
  end

  # Notifies after user mention by sending email to the mentioned user
  # @param [Symbol] notification_type - either :ck_notify_journal (if mention is in the new journal
  #   message), :ck_notify_creation (if mention is in the new issue description) or
  #   :ck_notify_update (if mention is in the updated issue description)
  # @param [Issue] issue - AR Issue object of the issue, which description or journal contains mention
  # @param [String] text - text in which mention is contained (issue description or journal)
  def notify_user(notification_type, issue, text)
    return if RedmineCkeditorSetting.issue_mentions_notify_on.to_i.zero?

    if notification_type == :ck_notify_update
      orig_issue = Issue.find_by(id: issue.id)
      return if orig_issue && orig_issue.description == text
    end

    matches = text.scan(/user-mention-link-\d+/)

    matches.uniq.each do |match|
      notified_id = match.split('-').last.to_i
      next if notified_id == issue.assigned_to_id || notified_id == issue.author_id

      notified_user = User.find_by(id: notified_id)
      next unless notified_user

      notified_user_mail = notified_user.mail
      next unless notified_user_mail

      mail_subject = notification_user_subject(notification_type, issue.id, issue.subject)
      mail_msg = notification_user_msg(notification_type, notified_id, issue.id, issue.subject, text)

      RedmineCkeditorMailer.send_notification(
        notified_user_mail,
        mail_subject,
        mail_msg
      ).deliver_later
    end

  end

  # Prepares issue notification journal message - i.e. replaces all placeholders in the given text
  # with real values (passed as further parameters to the method)
  # @param [Symbol] notification_type - either :ck_notify_journal, :ck_notify_creation or
  #   :ck_notify_update - these values will be used as locale key to get translated action value
  # @param [Integer] notified_id - is of the issue, which will be notified
  # @param [Integer] id - id of the issue, which description or journal contains mention
  # @param [String] subject - subject of the issue, which description or journal contains mention
  # @param [String] mention_text - text in which mention is contained (issue description or journal)
  def notification_issue_msg(notification_type, notified_id, id, subject, mention_text)
    url = "#{Setting.protocol}://#{Setting.host_name}/issues/#{id}"

    text = RedmineCkeditorSetting.issue_mentions_notification_msg.dup
    text.gsub!('%issue_id%', link_to("##{id}", url))
    text.gsub!('%issue_notify_on%', l(notification_type))

    if text.include?('%issue_id_subject%')
      subj = if subject.length > 40
          subject[0, 37] + '...'
        else
          subject
        end
      text.gsub!(
        '%issue_id_subject%',
        link_to("##{id} (#{subj})", url)
      )
    end

    if text.include?('%mention_sentence%')
      context = highlight_notification_links(
        mention_text,
        "issue-mention-link-#{notified_id}",
        RedmineCkeditorSetting.issue_mentions_notification_style
      )
      text.gsub!('%mention_sentence%', context)
    end

    text
  end

  # Prepares user notification mail subject - i.e. replaces all placeholders in the given text with
  # real values (passed as further parameters to the method)
  # @param [Symbol] notification_type - either :ck_notify_journal, :ck_notify_creation or
  #   :ck_notify_update - these values will be used as locale key to get translated action value
  # @param [Integer] id - id of the issue, which description or journal contains mention
  # @param [String] subject - subject of the issue, which description or journal contains mention
  def notification_user_subject(notification_type, id, subject)
    text = RedmineCkeditorSetting.user_mentions_notification_subject.dup
    text.gsub!('%issue_id%', "##{id}")
    text.gsub!('%issue_notify_on%', l(notification_type))

    if text.include?('%issue_id_subject%')
      subj = if subject.length > 40
          subject[0, 37] + '...'
        else
          subject
        end
      text.gsub!(
        '%issue_id_subject%',
        "##{id} (#{subj})"
      )
    end

    text
  end

  # Prepares user notification mail body - i.e. replaces all placeholders in the given text
  # with real values (passed as further parameters to the method)
  # @param [Symbol] notification_type - either :ck_notify_journal, :ck_notify_creation or
  #   :ck_notify_update - these values will be used as locale key to get translated action value
  # @param [Integer] notified_id - id of the user, who will be notified
  # @param [Integer] id - id of the issue, which description or journal contains mention
  # @param [String] subject - subject of the issue, which description or journal contains mention
  # @param [String] mention_text - text in which mention is contained (issue description or journal)
  def notification_user_msg(notification_type, notified_id, id, subject, mention_text)
    url = "#{Setting.protocol}://#{Setting.host_name}/issues/#{id}"

    text = RedmineCkeditorSetting.user_mentions_notification_msg.dup
    text.gsub!('%issue_id%', link_to("##{id}", url))
    text.gsub!('%issue_notify_on%', l(notification_type))

    if text.include?('%issue_id_subject%')
      subj = if subject.length > 40
          subject[0, 37] + '...'
        else
          subject
        end
      text.gsub!(
        '%issue_id_subject%',
        link_to("##{id} (#{subj})", url)
      )
    end

    if text.include?('%mention_sentence%')
      context = highlight_notification_links(
        mention_text,
        "user-mention-link-#{notified_id}",
        RedmineCkeditorSetting.user_mentions_notification_style
      )
      text.gsub!('%mention_sentence%', context)
    end

    text
  end

  # Highlights links of mentioned issues or users in the text, where the mentions are placed (either
  # issue description or journal)
  # @param [String] text - html text containing mentioned issue or user links
  # @param [String] class_name - css class of mentioned links (links can be identified by this class)
  # @param [String] style - css styles, which will be added as inline styles to the mention links to
  #                         highlight them in the given html text
  # @return [String] - html text with highlighted mentioned issue or user links
  def highlight_notification_links(text, class_name, style)
    # Parse the HTML string using Nokogiri
    doc = Nokogiri::HTML(text)

    # Find all link elements with the specified class
    links = doc.css("a.#{class_name}")

    # Iterate over each link and apply the style
    links.each do |link|
      link['style'] = style
    end

    # Return the modified HTML text
    doc.to_html
  end
end