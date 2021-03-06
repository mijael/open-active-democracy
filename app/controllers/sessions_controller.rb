# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController

  def new
    @page_title = t('sessions.new.title', :government_name => current_government.name)
    @user = User.new
    @signup = Signup.new    
    respond_to do |format|
      format.html
      format.js { render_to_facebox }
    end
  end

  def create
    Rails.logger.debug("BLAH -5: #{session[:return_to]}")
    self.current_user = User.authenticate(params[:email], params[:password])
    respond_to do |format|
        format.html {
          if logged_in?
            if params[:remember_me] == "1"
              current_user.remember_me unless current_user.remember_token?
              cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
            end
            redirect_back_or_default('/')
            flash[:notice] = t('sessions.create.success', :user_name => current_user.name)
          else
            flash[:error] = t('sessions.create.failed')
            render :action => 'new'
          end          
        }
        format.js {
          Rails.logger.debug("BLAH -4: #{session[:return_to]}")
          if logged_in?
            Rails.logger.debug("BLAH -3: #{session[:return_to]}")
            if session[:priority_id] # they were trying to endorse a priority, so let's go ahead and add it and take htem to their priorities page immediately
              Rails.logger.debug("BLAH -2: #{session[:return_to]}")
              @priority = Priority.find(session[:priority_id])
              @value = session[:value].to_i
              if @priority
                if @value == 1
                  @priority.endorse(current_user,request,current_partner,@referral)
                else
                  @priority.oppose(current_user,request,current_partner,@referral)
                end
              end  
              session[:priority_id] = nil
              session[:value] = nil
            end            
            Rails.logger.debug("BLAH -1: #{session[:return_to]}")
            flash[:notice] = t('sessions.create.success', :user_name => current_user.name) 
            current_user.remember_me unless current_user.remember_token?
            cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
            Rails.logger.debug("BLAH: #{session[:return_to]}")
            redirect_from_facebox(session[:return_to] ? session[:return_to] : "/")
          else
            if params[:region] == 'inline'
              render :update do |page|
                page.replace_html 'login_message', t('sessions.create.try_again')
              end
            else
              flash[:error] = t('sessions.create.try_again')
              render_to_facebox(:action => "new")
            end
          end          
        }
    end        
  end

  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session    
    flash[:notice] = t('sessions.destroy')
    redirect_back_or_default('/')
  end
  
end
