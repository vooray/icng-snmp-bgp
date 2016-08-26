#!/usr/bin/ruby

require 'snmp'
require 'slop'

# host = '192.168.23.130'
# peer = '192.168.0.2'
# community = 'public'
$oid_bgpPeerState = '1.3.6.1.2.1.15.3.1.2.'
$oid_bgpPeerAdminStatus = '1.3.6.1.2.1.15.3.1.3.'
$nagiosReturnCodes = {Ok: 0, Warning: 1, Critical: 2, Unknown: 3}

opts = Slop.parse do |o|
  o.string '-h', 'hostname'
  o.string '-C', 'community'
  o.string '-p', 'peer'
end

if ARGV.size == 0
  puts opts
  Kernel.exit(3)
end

host = opts[:h]
peer = opts[:p]
community = opts[:C]


def snmp_get(host, community, oid)
  begin
    manager = SNMP::Manager.new(:host => host, :community => community)
    response = manager.get(oid)
    return response.varbind_list[0].value
  rescue Exception => e
    #puts "Got exception"
    puts e.message
    #puts e.backtrace
    Kernel.exit(3)
  ensure
    manager.close unless manager.nil?
  end
end

def get_bgpPeerState(host, community, peer)
  bgpPeerState = snmp_get(host, community, $oid_bgpPeerState + peer.to_s)
end

def get_bgpPeerAdminStatus(host, community, peer)
  bgpPeerAdminStatus = snmp_get(host, community, $oid_bgpPeerAdminStatus + peer.to_s)
end

def get_bgpServiceStatus(bgpPeerState, bgpPeerAdminStatus)
  if bgpPeerAdminStatus == 1 # Admin Down (2 == Admin Up)
    puts "Warning - Peer is in Admin Down state"
    Kernel.exit($nagiosReturnCodes[:Warning])
  elsif bgpPeerState == 6 # Established
    puts "Ok - Established"
    Kernel.exit($nagiosReturnCodes[:Ok])
  else
    puts "Critical"
    Kernel.exit($nagiosReturnCodes[:Critical])
  end
end


bgpPeerState = get_bgpPeerState(host, community, peer)
bgpPeerAdminStatus = get_bgpPeerAdminStatus(host, community, peer)
get_bgpServiceStatus(bgpPeerState,bgpPeerAdminStatus)