class Api::PointsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate

  def index
    limit = params[:limit].present? ? params[:limit].to_i : 5
    limit = [limit, 25].min
    render json: Point.where(active: true).order(points: :desc).limit(limit).offset(params[:offset])
  end

  def show
    user_points = Point.find_by(discord_id: params[:id])

    if user_points.present?
      render json: user_points
    else
      render json: { message: 'Unable to find that user' }
    end
  end

  def create
    user_points = Point.find_or_create_by(discord_id: params[:discord_id].to_i)
    value = params.fetch(:value, 1).to_i

    if user_points.increment_points_by(value)
      user_points.update(active: true)
      render json: user_points
    else
      render json: { message: 'Unable to update points' }
    end
  end

  def update
    inactive_discord_ids = params[:inactive_discord_ids]
    active_discord_ids = params[:active_discord_ids]

    if inactive_discord_ids.present? && inactive_discord_ids.is_a?(Array)
      users = Point.where(discord_id: inactive_discord_ids).update_all(active: false)
      render json: { message: 'Users updated Successfully' }
    elsif active_discord_ids.present? && active_discord_ids.is_a?(Array)
      users = Point.where.not(discord_id: active_discord_ids).update_all(active: false)
      render json: {message: 'Users Updated Successfully'}
    else
      render json: { message: 'Invalid or missing Discord IDs' }
    end
  end

  private

  def authenticate
    authenticate_or_request_with_http_token do |token|
      ActiveSupport::SecurityUtils.secure_compare(token, ENV['ODIN_BOT_ACCESS_TOKEN'])
    end
  end
end
