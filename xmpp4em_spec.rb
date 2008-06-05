require 'xmpp4em'
require 'bacon'

shared 'eventmachine' do
  $bacon_thread = Thread.current
  def wait
    Thread.stop
    EM.add_timer(10) do
      wake
      should.flunk('waited too long')
    end
  end
  def wake
    $bacon_thread.wakeup
  end
end

describe 'XMPP4EM' do
  behaves_like 'eventmachine'

  @foo = XMPP4EM::Client.new('test1@jsierles.local', 't00tt00t', :auto_register => true)
  @bar = XMPP4EM::Client.new('test2@jsierles.local', 't00tt00t', :auto_register => true)

  it 'should login to an xmpp server' do
    @foo.on(:login) do
      @foo.send Jabber::Presence.new
      wake
    end

    @foo.connect
    wait

    @foo.should.be.connected?
  end

  it 'should send messages to others' do
    @bar.on(:login) do
      @bar.send Jabber::Presence.new do
        wake
      end
    end

    received = nil
    @bar.on(:message) do |msg|
      received = msg.first_element_text('//body')
      wake
    end

    @bar.connect
    wait

    @foo.send_msg 'test2@jsierles.local', 'hello'
    wait

    received.should == 'hello'
  end
end
