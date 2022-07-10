class CondominiosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_condominio, only: %i[ show edit update destroy ]
  load_and_authorize_resource

  # GET /condominios or /condominios.json
  def index
    if params[:nome] == nil || params[:nome] == ''
      @condominios = Condominio.all.order(:name)
    else 
      @condominios = Condominio.where("nome like ?", "%#{params[:nome]}%").order(:nome)
    end
    @condomini_amministrati = Condominio.where("EXISTS(SELECT 1 from condominos where condominos.condominio_id = condominios.id AND condominos.user_id = (?) AND condominos.is_condo_admin = true) ",current_user.id)
    @condomini_partecipante = Condominio.where("EXISTS(SELECT 1 from condominos where condominos.condominio_id = condominios.id AND condominos.user_id = (?) AND condominos.is_condo_admin = false) ",current_user.id)
    authorize! :index, Condominio
  end

  # GET /condominios/1 or /condominios/1.json
  def show
  end

  # GET /condominios/new
  def new
    @condominio = Condominio.new
    authorize! :new, Condominio
  end

  # GET /condominios/1/edit
  def edit
  end

  # POST /condominios or /condominios.json
  def create
    @condominio = Condominio.new(condominio_params)
    #@condominio.condominos_attributes = [{ condominio_id: params[:id], user_id: current_user.id, is_condo_admin: true }]
    respond_to do |format|
      if @condominio.save!
      	@condomino = Condomino.new(condominio_id: @condominio.id, user_id: current_user.id, is_condo_admin: true)
      	@condomino.save
        format.html { redirect_to condominio_url(@condominio), notice: "Condominio creato correttamente." }
        format.json { render :show, status: :created, location: @condominio }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @condominio.errors, status: :unprocessable_entity }
      end
    end
  end

  def comunication_for_admin
    authorize! :comunication_for_admin, Condominio
    if params.has_key?(:comune) && params.has_key?(:via) && params.has_key?(:nome) && params.has_key?(:message)
      if current_user.from_oauth?
        require 'json' 
        token, refresh_token = *JSON.parse(File.read('credentials.data'))
        client = Signet::OAuth2::Client.new(access_token: token,scope: 'gmail.send')
        service = Google::Apis::GmailV1::GmailService.new
        service.authorization = client
        m = Mail.new(
          to: Figaro.env.email_di_servizio, 
          from: current_user.email, 
          subject: "Comunicazione da un amministratore:",
          body: params[:message])
        message_object = Google::Apis::GmailV1::Message.new(raw: m.encoded) 
        service.send_user_message('me', message_object)
        redirect_to condominio_url(Condominio.find_by(nome: params[:nome])), :notice => "Mail inviata correttamente dal tuo account Gmail."
      else
        CondominioMailer.with(name: current_user.uname, email: current_user.email, condominio: params[:nome],comune: params[:comune] ,via: params[:via], message: params[:message]).new_comunication_mailer.deliver_later
        redirect_to condominio_url(Condominio.find_by(nome: params[:nome])), :notice => "Mail inviata correttamente."
      end
    else
      redirect_to root_path, :alert => "Errore nella creazione della mail."
    end
  end

  def create_comunication_for_admin
    authorize! :create_comunication_for_admin, Condominio
    @condominio_comunicazione = Condominio.find(params[:condominio_id])
  end

  

  # PATCH/PUT /condominios/1 or /condominios/1.json
  def update
    respond_to do |format|
      if @condominio.update(condominio_params)
        format.html { redirect_to condominio_url(@condominio), notice: "Condominio è stato aggiornato." }
        format.json { render :show, status: :ok, location: @condominio }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @condominio.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /condominios/1 or /condominios/1.json
  def destroy
    authorize! :destroy, Condominio
    @condominio_id = @condominio.id
    @condominio.destroy

    respond_to do |format|
      format.html { redirect_to condominios_url, notice: "Condominio è stato eliminato correttamente." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_condominio
      @condominio = Condominio.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def condominio_params
      params.require(:condominio).permit(:nome, :comune, :indirizzo, :latitudine, :longitudine, :flat_code,:avatar,:message,:via)
    end
end