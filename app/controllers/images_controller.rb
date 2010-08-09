class ImagesController < ApplicationController
  protect_from_forgery :except => :create

  before_authorization_filter :find_illustratable
  before_authorization_filter :find_user,         :only   => :create

  permit :show                    do may_view(@image)         end
  permit :edit, :update, :destroy do may_edit(@image)         end
  permit :new                     do may_edit(@illustratable) end
  permit :create                  do legitimate_user          end

  before_filter :only => [:create, :update] do
    if params[:result] == 'Cancel'
      flash[:notice] = "#{action_name.humanize} was cancelled."
      render :action => action_name
    end
  end

  private

  def find_illustratable
    find_resource :parent_as => 'illustratable'
  end

  public

  def show
    send_data(@image.data,
              :filename => @image.filename,
              :type => @image.content_type,
              :disposition => "inline")
  end

  def new
    @image = Image.new(:illustratable => @illustratable)
  end
  
  def edit
  end
  
  def create
    @image = @illustratable.images.build(params[:image])
    if @image.save
      flash[:notice] = 'Image was successfully added.'
    else
      flash[:alert] = 'Could not create image.'
    end
  end

  def update
    if @image.update_attributes(params[:image])
      flash[:notice] = 'Image was successfully updated.'
    else
      flash[:alert] = 'Could not update image.'
    end
  end

  def destroy
    @image.destroy
    @image = nil
    flash[:notice] = "Successfully deleted image."
  end
end
