module RedmineWebhook
  class WebhookListener < Redmine::Hook::Listener
    def skip_webhooks(context)
      return true unless context[:request]
      return true if context[:request].headers['X-Skip-Webhooks']
      false
    end

    def controller_issues_new_after_save(context = {})
      return if skip_webhooks(context)
      issue = context[:issue]
      controller = context[:controller]
      project = issue.project
      webhooks = Webhook.where(:project_id => project.project.id)
      webhooks = Webhook.where(:project_id => 0) unless webhooks && webhooks.length > 0
      return unless webhooks
      post(webhooks, issue_to_json(issue, controller))
    end

    def controller_issues_edit_after_save(context = {})
      return if skip_webhooks(context)
      journal = context[:journal]
      controller = context[:controller]
      issue = context[:issue]
      project = issue.project
      webhooks = Webhook.where(:project_id => project.project.id)
      webhooks = Webhook.where(:project_id => 0) unless webhooks && webhooks.length > 0
      return unless webhooks
      post(webhooks, journal_to_json(issue, journal, controller))
    end

    def controller_issues_bulk_edit_after_save(context = {})
      return if skip_webhooks(context)
      journal = context[:journal]
      controller = context[:controller]
      issue = context[:issue]
      project = issue.project
      webhooks = Webhook.where(:project_id => project.project.id)
      webhooks = Webhook.where(:project_id => 0) unless webhooks && webhooks.length > 0
      return unless webhooks
      post(webhooks, journal_to_json(issue, journal, controller))
    end

    def model_changeset_scan_commit_for_issue_ids_pre_issue_update(context = {})
      issue = context[:issue]
      journal = issue.current_journal
      webhooks = Webhook.where(:project_id => issue.project.project.id)
      webhooks = Webhook.where(:project_id => 0) unless webhooks && webhooks.length > 0
      return unless webhooks
      post(webhooks, journal_to_json(issue, journal, nil))
    end

    private

    def issue_to_json(issue, controller)
      {
        title: "Redmine Issue ##{issue.id}",
        body: {
          text: "New issue created: #{issue.subject}\n\nDescription:\n#{issue.description}"
        },
        button: {
          label: "View Issue",
          url: controller.issue_url(issue)
        }
      }.to_json
    end
   
    def journal_to_json(issue, journal, controller)
      notes = journal.notes.present? ? "\n\nNotes:\n#{journal.notes}" : ""
      {
        title: "Redmine Issue ##{issue.id} Updated",
        body: {
          text: "Issue updated: #{issue.subject}#{notes}"
        },
        button: {
          label: "View Issue",
          url: controller.nil? ? issue.project.url : controller.issue_url(issue)
        }
      }.to_json
    end

    def post(webhooks, request_body)
      Thread.start do
        webhooks.each do |webhook|
          begin
            Faraday.post do |req|
              req.url webhook.url
              req.headers['Content-Type'] = 'application/json'
              req.body = request_body
            end
          rescue => e
            Rails.logger.error "Failed to send webhook: #{e.message}"
            Rails.logger.error e.backtrace.join("\n")
          end
        end
      end
    end
  end
end