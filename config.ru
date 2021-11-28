# frozen_string_literal: true

ENV['RACK_ENV'] ||= 'development'
require 'rubygems'
require 'bundler/setup'

require File.expand_path(File.join(File.dirname(__FILE__), 'server'))

run TriangularTextus
