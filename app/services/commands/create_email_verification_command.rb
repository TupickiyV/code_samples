class Commands::CreateEmailVerificationCommand
  attr_reader :results, :errors, :parsed_params

  def initialize(parsed_params:)
    @errors = []
    @parsed_params = parsed_params
  end

  def execute
    email = URI::DEFAULT_PARSER.unescape(email_verifications_params[:email]).downcase
    return false if blank_email?(email)

    email_verification = EmailVerification.find_or_create_by(email: email)
    email_verification.update(guid: email_verifications_params[:guid],
                              token: email_verification.token.presence || SecureRandom.uuid)
    ProjectMailer.send_email_with_verification(email_verification).deliver
    @results = { message: :sent }
    true
  end

  private

  def blank_email?(email)
    return false if email.present?

    @errors.push({ message: "Incorrect email" })
    true
  end

  def email_verifications_params
    parsed_params.permit(:email, :guid)
  end
end
