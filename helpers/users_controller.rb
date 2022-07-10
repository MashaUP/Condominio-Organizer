class UsersController < ApplicationController

    def new
        @user = User.new
    end

    def create
        @user = User.new(user_params)
        if @user.save
            session[:user_id] = @user.id
            redirect_to root_path
        else
            render :new
        end
    end
     
    def show
        @user = User.find(parans[:id])
    end

    private

    def user_params
        parans.require(:user).permit(:username,:password)
    end
end