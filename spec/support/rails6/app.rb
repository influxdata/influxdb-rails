require "action_controller/railtie"
require "active_record/railtie"

app = Class.new(Rails::Application)
app.config.secret_key_base = "1234567890abcdef1234567890abcdef"
app.config.secret_token = "1234567890abcdef1234567890abcdef"
app.config.session_store :cookie_store, key: "_myapp_session"
app.config.active_support.deprecation = :log
app.config.eager_load = false
app.config.root = __dir__
Rails.backtrace_cleaner.remove_silencers!
app.initialize!

app.routes.draw do
  resources :metrics, only: :index
  resources :exceptions, only: :index
end

InfluxDB::Rails.configure do |config|
end

ENV["DATABASE_URL"] = "sqlite3::memory:"
ActiveRecord::Schema.define do
  create_table :metrics, force: true do |t|
    t.string :name

    t.timestamps
  end
end

class Metric < ActiveRecord::Base; end
class ApplicationController < ActionController::Base; end
class MetricsController < ApplicationController
  prepend_view_path File.join(__dir__, "..", "views")

  before_action do
    InfluxDB::Rails.current.values = { additional_value: :value }
    InfluxDB::Rails.current.tags = { additional_tag: :value }
  end

  def index
    Metric.create!(name: "name")
  end
end

class ExceptionsController < ApplicationController
  def index
    1 / 0
  end
end

Object.const_set(:ApplicationHelper, Module.new)
