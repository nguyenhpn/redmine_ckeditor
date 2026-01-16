# This file is a part of Redmine CKEditor plugin
# for Redmine
#
# Copyright 2020-2024 RedmineX. All Rights Reserved.
# https://www.redmine-x.com
#
# Licensed under GPL v2 (http://www.gnu.org/licenses/gpl-2.0.html)
# Created by Ondřej Svejkovský

class RedmineCkeditorController < ApplicationController
  include AvatarsHelper

  before_action :find_project

  # Delivers data of user mention suggestions
  def users
    users_query = helpers.user_suggestions_query(params[:name], @project)
    suggestions_data = helpers.prepare_user_suggestions(users_query)

    render json: suggestions_data
  end

  def issues
    issues_query = helpers.issue_suggestions_query(params[:name], @project)
    suggestions_data = helpers.prepare_issue_suggestions(issues_query)

    render json: suggestions_data
  end

  private

  def find_project
    @project = Project.find_by(id: params[:project_id])
  end
end