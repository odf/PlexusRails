class CommentsController < ApplicationController
  before_authorization_filter :find_resource, :except => [:new, :create]

  permit :new, :create            do may_edit(@commentable) end
  permit :edit, :update, :destroy do may_edit(@comment)     end

  redirect_if_cancelled

  def new
    @commentable = commentable(params)
    @comment = Comment.new(:commentable => @commentable, :author => current_user)
  end
  
  def edit
  end
  
  def create
    @commentable = commentable(params[:comment])
    @comment = @commentable.comments.build(params[:comment])
    if @commentable.save
      redirect_to(@commentable, :notice => 'Comment was successfully added.')
    else
      render :action => :new, :alert => 'Could not create comment.'
    end
  end

  def update
    if @comment.update_attributes(params[:comment])
      redirect_to(@comment.commentable,
                  :notice => 'Comment was successfully updated.')
    else
      render :action => :edit, :alert => 'Could not update comment.'
    end
  end

  def destroy
    @comment.destroy
    redirect_to @comment.commentable, :notice => "Successfully deleted comment."
  end

  private
  def commentable(params)
    if params[:on_class]
      model = params[:on_class].classify.constantize
      model.find(params[:on_id])
    end
  end
end
