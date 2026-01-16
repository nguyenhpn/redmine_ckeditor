# This file is a part of RedmineX Timesheet plugin
# for Redmine
#
# Copyright 2020-2024 RedmineX. All Rights Reserved.
# https://www.redmine-x.com
#
# Licensed under GPL v2 (http://www.gnu.org/licenses/gpl-2.0.html)
# Created by Ondřej Svejkovský

module RedmineCkeditor
  module SettingsControllerPatch
    def self.included(receiver)
      receiver.class_eval do
        helper :redmine_ckeditor
      end
    end
  end
end

unless SettingsController.included_modules.include?(RedmineCkeditor::SettingsControllerPatch)
  SettingsController.send(:include, RedmineCkeditor::SettingsControllerPatch)
end