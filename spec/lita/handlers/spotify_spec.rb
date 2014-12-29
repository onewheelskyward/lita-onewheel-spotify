require 'spec_helper'

describe Lita::Handlers::Spotify, :lita_handler => true do
  it 'searches spotify artists' do
    send_message '!spotify search artist rush'
    expect(replies.last).to include('https://open.spotify.com/artist/2Hkut4rAAyrQxRdof7FVJq')
  end

  it 'searches spotify tracks' do
    send_message '!spotify search track tom sawyer'
    expect(replies.last).to eq('Rush - Tom Sawyer.  https://open.spotify.com/track/1NSXPZZHSIfvEqCSxiDop7')
  end

  it 'searches spotify albums' do
    send_message '!spotify search album permanent waves'
    expect(replies.last).to eq('Rush - Permanent Waves.  https://open.spotify.com/album/2gHaOUnuXm0VheySMhvImb')
  end
end
