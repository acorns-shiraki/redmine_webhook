if Rails.try(:autoloaders).try(:zeitwerk_enabled?)
  Rails.autoloaders.main.push_dir File.dirname(__FILE__) + '/lib/redmine_webhook'
  RedmineWebhook::ProjectsHelperPatch
  RedmineWebhook::WebhookListener
else
  require "redmine_webhook"
end

Redmine::Plugin.register :redmine_webhook do
  name 'Redmine Webhook plugin for LINEWORKS'
  author 't.shiraki'
  description 'Redmine webook plugin for LINEWORKS integration'
  version '0.0.1'
  url 'https://github.com/acorns-shiraki/redmine_webhook'
  author_url ''
  project_module :webhooks do
    permission :manage_hook, {:webhook_settings => [:index, :show, :update, :create, :destroy]}, :require => :member
  end
end
