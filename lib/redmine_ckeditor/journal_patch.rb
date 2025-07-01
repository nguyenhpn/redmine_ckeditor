module RedmineCkeditor
  module JournalPatch
    include RedmineCkeditorHelper

    def self.included(receiver)
      receiver.send(:include, InstanceMethods)
      receiver.class_eval do
        attr_accessor :do_not_notify

        after_create  :send_mention_notifications_after_create
        #before_update  :send_mention_notifications_before_update
      end
    end

    module InstanceMethods
      # Sends notification to issue or user after journal is created
      def send_mention_notifications_after_create
        # No notification if new journal is created as notification of another issue
        return if do_not_notify

        if RedmineCkeditorSetting.issue_mentions &&
           RedmineCkeditorSetting.issue_mentions_notifications &&
           RedmineCkeditorSetting.issue_mentions_notify_on.to_i >= 0

          notify_issue(:ck_notify_journal, issue, notes)
        end
        if RedmineCkeditorSetting.user_mentions &&
           RedmineCkeditorSetting.user_mentions_notifications &&
           RedmineCkeditorSetting.user_mentions_notify_on.to_i >= 0

          notify_user(:ck_notify_journal, issue, notes)
        end
      end

    end # module InstanceMethods

  end # module JournalPatch
end # module RedmineCkeditor
