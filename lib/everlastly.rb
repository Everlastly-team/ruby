# everlastly.py: Everlastly API implementation
#
# Copyright © 2016 Emelyanenko Kirill
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

require 'rest-client'
require 'openssl'
require 'open-uri'
require 'json'
require 'addressable/uri'

module Everlastly

  class << self
    attr_accessor :configuration
  end

  def self.setup
    @configuration ||= Configuration.new
    yield( configuration )
  end

  class Configuration
    attr_accessor :public_key, :private_key

    def intialize
      @public_key    = ''
      @private_key   = ''
    end
  end

  def self.get_receipts(receipts, params={})
    payload = { uuids: JSON.dump(receipts)}
    payload[:nonce] = (Time.now.to_f * 10000000).to_i unless params[:no_nonce] 
    begin
      response = JSON.parse(post('get_receipts', payload))
      { success: true, receipts: response["receipts"] }
    rescue JSON::ParserError
      { success: false, error_message: "Strange answer from server" }
    rescue RestClient::Exception
      { success: false, error_message: "Network error" }
    rescue SocketError
      { success: false, error_message: "Network error" }
    end
  end

  def self.anchor(dochash, params={})
    payload = { hash: dochash } 
    if params[:no_nonce] then
      payload[:no_nonce]='True'
    else
      payload[:nonce] = (Time.now.to_f * 10000000).to_i
    end
    payload[:metadata] = JSON.dump(params[:metadata]) if params[:metadata] 
    payload[:no_salt] = 'True' if params[:no_salt] 
    payload[:save_dochash_in_receipt] = 'True' if params[:save_dochash_in_receipt]
    begin
      response = JSON.parse(post('anchor', payload))      
      { success: (response["status"]=="Accepted"), error_message: response["error"], receiptID: response["receiptID"] }
    rescue JSON::ParserError
      { success: false, error_message: "Strange answer from server" }
    rescue RestClient::Exception
      { success: false, error_message: "Network error" }
    rescue SocketError
      { success: false, error_message: "Network error" }
    end
  end

 protected

  def self.resource
    @@resouce ||= RestClient::Resource.new( 'https://everlastly.com/api/v1/' )
  end


  def self.post( command, payload )
    encoded_payload = Addressable::URI.form_encode(payload)
    sign = OpenSSL::HMAC.hexdigest( 'sha512', configuration.private_key , encoded_payload )
    resource[ command ].post encoded_payload, { "pub-key" => configuration.public_key , sign: sign, 'content-type' => 'application/x-www-form-urlencoded' }
  end


end
