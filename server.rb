# frozen_string_literal: true

require 'ruby/openai'
require 'sinatra'

begin
  require 'awesome_print'
  require 'dotenv'
  require 'pry-byebug'
rescue LoadError; end # rubocop:disable Lint/SuppressedException
class TriangularTextus < Sinatra::Base
  set :root, File.dirname(__FILE__)
  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }

  not_found do
    status 404
    erb :fourohfour
  end

  OPENAI_CLIENT = OpenAI::Client.new(access_token: ENV['OPENAI_ACCESS_TOKEN'])

  STORIES = YAML.load_file('texts.yml').map do |story|
    story.gsub(/\*\*\*/, '<input class="blank" type="text"><span class="spacer"></span>')
  end

  MAX_LENGTH = 2000
  TEMPERATURE = 0.9
  # TOP_K = 9
  TOP_P = 1.0
  REPETITION_PENALTY = 1.4
  FREQUENCY_PENALTY = 0.52

  MAX_TIMES = 1

  get '/' do
    erb :index, locals: { story: STORIES.sample(1).first }
  end

  post '/submit' do
    request.body.rewind
    body = request.body.read
    payload = JSON.parse(body)

    prompt = payload['text'].to_s.strip

    session['prompt'] = "#{prompt} "

    {}.to_json
  end

  get '/complete' do
    redirect '/' if session['prompt'].nil?

    erb :complete
  end

  post '/generate' do
    prompt = session['prompt']

    result = sequence(prompt)

    { result: result[:text].force_encoding('UTF-8').gsub(/&nbsp;/, ' ') }.to_json
  end

  private def sequence(prompt, finish: false)
    parameters = parameters(prompt)

    if finish
      parameters[:logit_bias] = { '13': 5, # ensure a period exists
                                  '50256': 5, # ensure the text can end
                                  '4841': -100, # exclude weird ____________________
                                  '1427': -100 }
    end

    generated_sequences = OPENAI_CLIENT.completions(engine: 'curie', parameters: parameters)
    text = generated_sequences['choices'][0]['text']

    if text.empty?
      parameters[:temperature] = 0.7
      generated_sequences = OPENAI_CLIENT.completions(engine: 'curie', parameters: parameters)
      text = generated_sequences['choices'][0]['text']
    end

    if finish
      # clean_finish = text.sub(/\.[^")]+/, '.')
      { text: "#{prompt} #{convert_newlines(text)}" }
    else # go one more time
      sequence("#{prompt} #{text}", finish: true)
    end
  end

  private def convert_newlines(text)
    text.gsub(/\n+/, '<br />')
  end

  private def parameters(prompt)
    { prompt: prompt, max_tokens: MAX_LENGTH - (prompt.length / 4), temperature: TEMPERATURE, top_p: TOP_P,
      frequency_penalty: FREQUENCY_PENALTY, n: 1 }
  end
end
