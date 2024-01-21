class Api::SearchController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate

  def index
    query = params[:q].scan(/\b\w+\b/)
    path = find_path(query)
    records = TfIdf
              .where(word: query)
              .group(:search_record_id)
              .select('search_record_id, SUM(score) as total_score')
              .order('total_score DESC')
              .map(&:search_record_id)
              .flat_map { |id| path ? SearchRecord.where(id:, path:) : SearchRecord.where(id:) }
    render json: records
  end

  private

  def find_path(query)
    if query.intersect?(%w[javascript node nodejs js])
      'full-stack-javascript'
    elsif query.intersect?(%w[ruby rails rail])
      'full-stack-ruby-on-rails'
    elsif query.intersect?(%w[foundation foundations])
      'foundations'
    else
      nill
    end
  end

  def retrieve_records(ids)
    ids.map do |id|
      SearchRecord.where(id:)
    end
  end

  def authenticate
    authenticate_or_request_with_http_token do |token|
      ActiveSupport::SecurityUtils.secure_compare(token, ENV['ODIN_BOT_ACCESS_TOKEN'])
    end
  end
end
