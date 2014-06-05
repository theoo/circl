=begin
  CIRCL Directory
  Copyright (C) 2011 Complex IT sàrl

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as
  published by the Free Software Foundation, either version 3 of the
  License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

class People::CommentsController < ApplicationController

  layout false

  load_resource :person
  before_filter :load_comments, only: :index
  before_filter :create_comment, only: :create
  before_filter :load_comment, except: [:index, :create]
  authorize_resource

  monitor_changes :@comment

  def index
    respond_to do |format|
      format.json { render json: @comments }
    end
  end

  def show
    edit
  end

  def create
    respond_to do |format|
      if @comment.save
        format.json  { render json: @comment }
      else
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render json: @comment }
    end
  end

  def update
    respond_to do |format|
      if @comment.update_attributes(params[:comment])
        format.json { render json: @comment }
      else
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @comment.destroy
        format.json { render json: {} }
      else
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end


  private

  def load_comments
    @comments = @person.comments_edited_by_others
  end

  def create_comment
    @comment = current_person.edited_comments.new params[:comment]
  end

  def load_comment
    @comment = @person.comments_edited_by_others.find params[:id]
  end

end
