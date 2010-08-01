#!/usr/bin/ruby

require 'timeout'
require 'socket'
include Socket::Constants

def traceroute(destination)
  begin
    dest_address = IPSocket.getaddress(destination)
  rescue Exception => e
    puts "Can not resolve #{dest}"
    puts e.message
    return
  end
  
  port = 33434
  ttl  = 1
  max_hops = 30
  
  while true
    recv_socket = Socket.new(Socket::AF_INET, Socket::SOCK_RAW, Socket::IPPROTO_ICMP)
    recv_socket.bind(Socket.pack_sockaddr_in(port, ""))
    
    send_socket = Socket.new(Socket::AF_INET, Socket::SOCK_DGRAM, Socket::IPPROTO_UDP)
    send_socket.setsockopt(0, Socket::IP_TTL, ttl)
    send_socket.connect(Socket.pack_sockaddr_in(port, destination))
    send_socket.puts ""
    
    curr_addr = nil
    curr_name = nil
    
    begin
      Timeout.timeout(1) { 
        data, sender = recv_socket.recvfrom 8192 
        curr_addr = Socket.unpack_sockaddr_in(sender)[1].to_s
      }
      
      begin
        curr_name = Socket.getaddrinfo(curr_addr, 0, Socket::AF_UNSPEC, Socket::SOCK_STREAM, nil, Socket::AI_CANONNAME)[0][2]
      rescue SocketError => e
        curr_name = curr_addr
      end
      
      #puts curr_name
      if curr_name.empty?
        curr_host = "*"
      else
        curr_host = "#{curr_name} (#{curr_addr})"
      end
      puts "#{ttl}\t#{curr_host}"
      
      if curr_addr == dest_address or ttl > max_hops
        break
      end
    rescue Timeout::Error
      puts "#{ttl}\t*"
    ensure
      recv_socket.close
      send_socket.close
    end
    
    ttl = ttl + 1
  end  
end

traceroute("google.com")
