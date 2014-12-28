require 'spec_helper'

describe Lita::Handlers::Spotify, lita_handler: true do
  it 'searches spotify' do
    send_message '!spotify rush'
    expect(replies.last).to eq('rush')
  end
end
