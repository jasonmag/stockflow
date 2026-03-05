class DailyRemindersJob < ApplicationJob
  queue_as :default

  def perform
    Business.includes(:users).find_each do |business|
      lead = business.reminder_lead_days
      due_target = Date.current + lead.days

      business.payables.where(due_on: due_target).find_each do |payable|
        create_notification_for_all_users(business, payable, "Payable due on #{payable.due_on}: #{payable.payee}", payable.due_on)
      end

      business.payables.overdue_list.find_each do |payable|
        create_notification_for_all_users(business, payable, "Overdue payable: #{payable.payee}", payable.due_on)
      end

      business.receivables.where(due_on: due_target).find_each do |receivable|
        create_notification_for_all_users(business, receivable, "Receivable due on #{receivable.due_on}: #{receivable.reference}", receivable.due_on)
      end

      business.receivables.overdue_list.find_each do |receivable|
        create_notification_for_all_users(business, receivable, "Overdue receivable: #{receivable.reference}", receivable.due_on)
      end
    end
  end

  private
    def create_notification_for_all_users(business, notifiable, message, due_on)
      business.users.find_each do |user|
        Notification.find_or_create_by!(business:, user:, notifiable:, message:, due_on:)
      end
    end
end
