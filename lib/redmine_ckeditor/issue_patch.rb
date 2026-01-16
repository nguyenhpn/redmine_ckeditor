module RedmineCkeditor
  module IssuePatch
    include RedmineCkeditorHelper

    def self.included(receiver)
      receiver.send(:include, InstanceMethods)
      receiver.class_eval do
        after_create  :send_mention_notifications_after_create
        before_update  :send_mention_notifications_before_update
      end
    end

    module InstanceMethods
      # Sends notification to issue or user after issue was created
      def send_mention_notifications_after_create
        if RedmineCkeditorSetting.issue_mentions &&
           RedmineCkeditorSetting.issue_mentions_notifications &&
           RedmineCkeditorSetting.issue_mentions_notify_on.to_i >= 1

          notify_issue(:ck_notify_creation, self, description)
        end
        if RedmineCkeditorSetting.user_mentions &&
           RedmineCkeditorSetting.user_mentions_notifications &&
           RedmineCkeditorSetting.user_mentions_notify_on.to_i >= 1

          notify_user(:ck_notify_creation, self, description)
        end
      end

      # Sends notification to issue or user before issue is updated
      def send_mention_notifications_before_update
        if RedmineCkeditorSetting.issue_mentions &&
           RedmineCkeditorSetting.issue_mentions_notifications &&
           RedmineCkeditorSetting.issue_mentions_notify_on.to_i >= 2

          notify_issue(:ck_notify_update, self, description)
        end
        if RedmineCkeditorSetting.user_mentions &&
           RedmineCkeditorSetting.user_mentions_notifications &&
           RedmineCkeditorSetting.user_mentions_notify_on.to_i >= 2

          notify_user(:ck_notify_update, self, description)
        end
      end

    end # module InstanceMethods

  end # module IssuePatch
end # module RedmineCkeditor
