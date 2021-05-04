class ReportToScmJob < CreateJob
  # We don't properly capitalize SCM in the class name since CreateJob is doing `CLASS_NAME.to_s.camelize.safe_constantize`
  queue_as :scm

  def perform(event_id)
    event = Event::Base.find(event_id)
    return true unless event

    EventSubscription.joins('INNER JOIN events ON event_subscriptions.eventtype = events.eventtype')
                     .where(events: { eventtype: ['Event::BuildFail', 'Event::BuildSuccess'], id: event_id }, channel: :scm)
                     .where.not(token_id: nil)
                     .order('events.created_at ASC').each do |event_subscription|
      begin
        SCMStatusReporter.new(subscription.payload, subscription.token.scm_token, subscription.eventtype).call
      rescue StandardError => e
        Airbrake.notify(e, event_id: event_id)
        event.undone_jobs -= 1
      end
    end

    true
  end
end
