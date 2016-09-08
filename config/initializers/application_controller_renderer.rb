# Be sure to restart your server when you modify this file.

ApplicationController.renderer.defaults.merge!(
  http_host: Rails.configuration.settings["host"],
  https: Rails.configuration.settings["ssl"]
)
