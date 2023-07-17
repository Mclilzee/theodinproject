class Api::PointsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate

  def index
    render json: Point.all.order(points: :desc).limit(params[:limit]).offset(params[:offset])
  end

  def show
    sql_query = 'SELECT *, rank FROM (SELECT *, RANK() OVER (ORDER BY points DESC, id) FROM points) AS rank WHERE discord_id = ? LIMIT 1;'
    user = Point.find_by_sql([sql_query, params[:id]])
||||||| parent of 1ed6be59 (Update show response to include user ranking)
    user_points = Point.find_by(discord_id: params[:id])

    if user.present?
      render json: user.first
||||||| parent of 1ed6be59 (Update show response to include user ranking)
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
      render json: user_points
    else
      render json: { message: 'Unable to update points' }
    end
  end

  private

  def authenticate
    authenticate_or_request_with_http_token do |token|
      ActiveSupport::SecurityUtils.secure_compare(token, ENV['ODIN_BOT_ACCESS_TOKEN'])
    end
  end
end
