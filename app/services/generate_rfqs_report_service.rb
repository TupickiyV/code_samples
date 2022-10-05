# frozen_string_literal: true

class GenerateRfqsReportService
  def initialize(period: "daily")
    @period = period
    @range = range(period)
    @active_rfqs_count = 0
    @date_for_csv = @period == "daily" ? Date.yesterday.strftime("%Y-%m-%d") : @range.to_s
  end

  def generate_usage_report
    csv_data = generate_csv(current_open_rfqs)

    report_list.each do |email|
      Mailer.send_report(email, csv_data, @period.titleize, @date_for_csv).deliver
    end
  end

  def generate_csv(attrs)
    CSV.generate(encoding: "UTF-8") do |csv|
      csv_header_rows.each do |head|
        csv << head
      end
      base_columns(csv)
      monthly_supplier_columns(csv, attrs) if @period == "monthly"
      additional_columns(csv, attrs)
    end
  end

  private

  def base_columns(csv)
    csv << []
    csv << ["Number of RFQs sent", sent_to_vendor_rfqs.count]
    csv << ["Number of current Open RFQs", @active_rfqs_count]
    csv << []
  end

  def monthly_supplier_columns(csv, attrs)
    csv << ["Supplier Usage", "Count"]
    attrs[:companies_info].each do |k, v|
      csv << [k, v]
    end
    csv << []
  end

  def additional_columns(csv, attrs)
    csv << ["k1", "k2", "k3", "k4", "k5", "k6", "k7", "k8"]
    attrs.sort_by { |_k, v| v[:v8].to_s }.each do |_k, v|
      next if v[:v1].blank?

      csv << [v[:v1], v[:v2].to_i, v[:v3].to_i, v[:v4].to_i, v[:v5].to_i, v[:v6].to_i, v[:v7], v[:v8]]
    end
  end

  def csv_header_rows
    [["#{@period.titleize} Report", @date_for_csv]]
  end

  def sent_to_vendor_rfqs
    @sent_to_vendor_rfqs ||= Rfq.joins(:project).where(sent_at: @range, projects: { demo: false })
  end

  def report_list
    @report_list ||= ReportEmail.distinct.pluck(:name)
  end

  def current_open_rfqs
    rfqs = { companies_info: {} }
    sent_to_vendor_rfqs.includes(:project).each do |rfq|
      project_id = rfq.project_id
      rfqs[project_id] = initialize_rfqs_info if rfqs[project_id].blank?
      quotes = quotes(rfq)
      @active_rfqs_count += 1 if quotes.any?
      rfqs = fetch_rfqs_info(rfqs, rfq, project_id, quotes)
    end
    rfqs
  end

  def companies(quotes, colocation)
    colocation ? quotes.map(&:company_name).uniq : quotes.map(&:network_provider_name).uniq
  end

  def fetch_rfqs_info(rfqs, rfq, project_id, quotes)
    key = Rfq::SHORT_NAME_BY_RFQ_TYPE[rfq.service_category_name].to_sym
    rfqs[project_id][:v1] = rfq.project.admin_label
    rfqs[project_id][:v7] = "#{project.user_email} | #{project.user.name}"
    rfqs[project_id][:v8] = project.company_name
    rfqs[project_id][key] = quotes_count_by_rfq_type(quotes, rfq)
    rfqs
  end

  def quotes_count_by_rfq_type(quotes, rfq)
    quotes.map(&:quote_type).uniq.count(Rfq::QUOTE_TYPES_BY_RFQ_TYPE[rfq.service_category_name])
  end

  def quotes(rfq)
    rfq.project.quotes
      .where(quote_type: Rfq::QUOTE_TYPES_BY_RFQ_TYPE[rfq.service_category_name], data_center_availability: true)
  end

  def initialize_rfqs_info
    { key_1: 0, key_2: 0, key_3: 0, key_4: 0, key_5: 0 }
  end

  def range(period)
    case period
    when "daily"
      Date.yesterday.all_day
    when "weekly"
      Date.current.prev_week.all_week
    when "monthly"
      Date.current.prev_month.all_month
    end
  end
end
