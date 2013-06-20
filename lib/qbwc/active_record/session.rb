class QBWC::ActiveRecord::Session < QBWC::Session
  class QbwcSession < ActiveRecord::Base
    attr_accessible :company, :ticket, :user
  end

	def self.get(ticket)
		session = QbwcSession.find_by_ticket(ticket)
    self.new(session) if session
	end

  def initialize(session_or_user = nil, company = nil, ticket = nil)
    if session_or_user.is_a? QbwcSession
      @session = session_or_user
      super(@session.user, @session.company, @session.ticket)
      # Restore current job from saved one on QbwcSession
      @current_job = QBWC.jobs[@session.current_job.to_sym] if @session.current_job
      # Restore pending jobs from saved list on QbwcSession
      @pending_jobs = @session.pending_jobs.split(',').map { |job| QBWC.jobs[job.to_sym] }
    else
      super
      @session = QbwcSession.new(:user => self.user, :company => self.company, :ticket => self.ticket)
      self.save
      @session
    end
  end

  def save
    @session.pending_jobs = pending_jobs.map(&:name).join(',')
    @session.current_job = current_job.try(:name)
    @session.save
    super
  end

  def destroy
    @session.destroy
    super
  end

  [:error, :progress, :qbwc_iterating].each do |method|
    define_method method do
      @session.send(method)
    end
    define_method "#{method}=" do |value|
      @session.send("#{method}=", value)
    end
  end
  protected :progress=, :qbwc_iterating=, :qbwc_iterating

end
