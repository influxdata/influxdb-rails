require "action_controller/railtie"
require "active_record"

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
  resources :widgets
end

InfluxDB::Rails.configure do |config|
end

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Schema.define do
  create_table :widgets, force: true do |t|
    t.string :title

    t.timestamps
  end
end

class Widget < ActiveRecord::Base; end
class ApplicationController < ActionController::Base; end
class WidgetsController < ApplicationController
  prepend_view_path File.join(__dir__, "..", "views")

  before_action do
    InfluxDB::Rails.current.values = { key: :value }
  end

  def index
    Widget.create!(title: "test")
  end

  def new
    1 / 0
  end
end

Object.const_set(:ApplicationHelper, Module.new)
