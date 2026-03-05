class NotificationsController < ApplicationController
  def index
    @unread = current_business.notifications.unread.order(due_on: :asc)
    @read = current_business.notifications.read.order(updated_at: :desc)
  end

  def mark_read
    notification = current_business.notifications.find(params[:id])
    notification.update!(status: :read)
    redirect_to notifications_path, notice: "Notification marked as read."
  end
end
