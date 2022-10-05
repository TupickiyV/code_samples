class EmailVerificationsController < ApiController
  def create
    cmd = Commands::CreateEmailVerificationCommand.new(parsed_params: parsed_params)
    if cmd.execute
      render json: cmd.results, status: :ok
    else
      render json: cmd.errors, status: :unprocessable_entity
    end
  end
end
