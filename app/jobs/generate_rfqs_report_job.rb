# frozen_string_literal: true

class GenerateRfqsReportJob < ApplicationJob
  queue_as :default

  def perform
    GenerateRfqsReportService.new(period: "daily").generate_usage_report

    if Date.current.beginning_of_week == Date.current
      GenerateRfqsReportService.new(period: "weekly").generate_usage_report
    end

    return unless Date.current.beginning_of_month == Date.current

    GenerateRfqsReportService.new(period: "monthly").generate_usage_report
  end
end
