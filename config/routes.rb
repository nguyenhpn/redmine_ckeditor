RedmineApp::Application.routes.draw do
  mount Rich::Engine => '/rich', :as => 'rich'
end

scope :redmine_ckeditor do
  get  'users',  to: 'redmine_ckeditor#users',  as: 'ckeditor_users',  format: :json
  get  'issues', to: 'redmine_ckeditor#issues', as: 'ckeditor_issues', format: :json
end
