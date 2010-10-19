#
# Copyright (C) 2008 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Original Author:: Jochen Hartmann (mailto:jhartmann@google.com)
#
# Simple class that contains all the methods listed in the 'Using Ruby with the 
# Google Data APIs' article
#
# Contains method for ClientLogin authentication and performing GET, 
# POST and PUT requests
#
#   SpreadsheetExamples: contains methods as build in the article
#
require 'net/http'
require 'net/https'
require 'rubygems'
require 'xml-simple'

# Contains all the methods listed in the 
# 'Using Ruby with the Google Data API's article'.
#
# Performs authentication via ClientLogin, feed retrieval, post and batch 
# update requests.
#
class SpreadsheetExamples
  
  SPREADSHEET_FEED = \
      'http://spreadsheets.google.com/feeds/spreadsheets/private/full'
  CONTENT_TYPE_FORM = 'application/x-www-form-urlencoded'
  CONTENT_TYPE_ATOMXML = 'application/atom+xml'

  attr_reader :headers
  attr_reader :wiki_entries
  # Authenticate with ClientLogin
  #
  # Args:
  #   email: string
  #   password: string
  #
  def authenticate(email, password)
    http = Net::HTTP.new('www.google.com', 443)
    http.use_ssl = true
    path = '/accounts/ClientLogin'
    data = "accountType=HOSTED_OR_GOOGLE&Email=#{email}" \
        "&Passwd=#{password}&service=wise"
    @headers = { 'Content-Type' => CONTENT_TYPE_FORM }
    resp, data = http.post(path, data, headers)
    cl_string = data[/Auth=(.*)/, 1]
    @headers["Authorization"] = "GoogleLogin auth=#{cl_string}"
  end

  # Set 'Content-Type' header to 'application/atom+xml'
  def set_header_content_type_to_xml()
    @headers["Content-Type"] = CONTENT_TYPE_ATOMXML
  end

  # Perform a GET request to a given uri
  #
  # Args:
  #   uri: string
  #
  # Returns:
  #   Net::HTTPResponse
  #
  def get_feed(uri)
    uri = URI.parse(uri)
    Net::HTTP.start(uri.host, uri.port) do |http|
      return http.get("#{uri.path}?#{uri.query}", @headers)
    end
  end

  # Parse xml into a datastructure using xmlsimple
  #
  # Args:
  #   xml: string
  #
  # Returns:
  #   A hash containing the xml data provided in the argument
  #
  def create_datastructure_from_xml(xml)
    return XmlSimple.xml_in(xml, 'KeyAttr' => 'name')
  end
    
  # Get spreadsheet feed for currently authenticated user
  def get_my_spreadsheets()
    spreadsheet_feed_response = get_feed(SPREADSHEET_FEED)
    create_datastructure_from_xml(spreadsheet_feed_response.body)
  end

  # Get the worksheets feed for a given spreadsheet
  #
  # Args:
  #   spreadsheet_key: string
  #
  # Returns:
  #   Net::HTTPResponse: The worksheet feed
  #
  def get_worksheet(spreadsheet_key)
    worksheet_feed_uri =  "http://spreadsheets.google.com/feeds/" <<
        "worksheets/#{spreadsheet_key}/private/full"
    worksheet_feed_response  = get_feed(worksheet_feed_uri) 
    create_datastructure_from_xml(worksheet_feed_response.body)
     
  end
  
  # Get the worksheets feed for a given spreadsheet
  #
  # Args:
  #   spreadsheet_key: string
  #
  # Returns:
  #   Net::HTTPResponse: The worksheet feed
  #
  def get_listfeed(spreadsheet_key)
    listfeed_uri =  "http://spreadsheets.google.com/feeds/list/#{spreadsheet_key}/od6/private/full"
    listfeed_response  = get_feed(listfeed_uri) 
    create_datastructure_from_xml(listfeed_response.body)
     
  end
  
  # Get the worksheets feed for a given spreadsheet
  #
  # Args:
  #   spreadsheet_key: string
  #
  # Returns:
  #   Net::HTTPResponse: The worksheet feed
  #
  def get_cellfeed(spreadsheet_key)
    cellfeed_uri =  "http://spreadsheets.google.com/feeds/cells/#{spreadsheet_key}/od6/private/full"
    cellfeed_response  = get_feed(cellfeed_uri) 
    create_datastructure_from_xml(cellfeed_response.body)
     
  end
  
  # Get the worksheets feed for a given spreadsheet
  #
  # Args:
  #   spreadsheet_key: string
  #
  # Returns:
  #   Net::HTTPResponse: The worksheet feed
  #
  def get_spreadsheet_key_by_title(spreadsheet_name)
    spreadsheets_uri = "http://spreadsheets.google.com/feeds/spreadsheets/private/full?title=#{spreadsheet_name}&title-exact=true"
    my_spreadsheets = get_feed(spreadsheets_uri)
    
    doc = create_datastructure_from_xml(my_spreadsheets.body)
   
    return doc["entry"][0]["id"][0][/full\/(.*)/, 1]
  end
  
  # Get the worksheets feed for a given spreadsheet
  #
  # Args:
  #   search_terms: string
  #
  # Returns:
  #   Net::HTTPResponse: The worksheet feed
  #
  def search_spreadsheet(spreadsheet_key, search_terms)
    
    listfeed_uri = "http://spreadsheets.google.com/feeds/list/#{spreadsheet_key}/od6/private/full"
    search_terms.map! do |st|
      URI.escape(st, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    end
    query = search_terms.join('+')
    spreadsheet_feed_response = get_feed("#{listfeed_uri}?q=#{query}")
    create_datastructure_from_xml(spreadsheet_feed_response.body)
  end
  
  # Get the worksheets feed for a given spreadsheet
  #
  # Args:
  #   spreadsheet_key: string
  #
  # Returns:
  #   Net::HTTPResponse: The worksheet feed
  #
  def search_all_worksheets(*search_terms)
    spreadsheet_feed_response = get_feed("#{SPREADSHEET_FEED}?q=#{search_terms.join('+')}")
    create_datastructure_from_xml(spreadsheet_feed_response.body)
  end

  # Post data to a specific uri
  #
  # Args:
  #   uri: string
  #   data: string (typically xml)
  #
  # Returns:
  #   Net::HTTPResponse
  #
  def post(uri, data)
    uri = URI.parse(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    return http.post(uri.path, data, @headers)
  end

  # Obtain the version string for a specific cell
  #
  # Args:
  #   uri: string
  #
  # Returns:
  #   A string containing the version string
  #
  def get_version_string(uri)
    response = get_feed(uri)
    xml = REXML::Document.new response.body
    # use XPath to strip the href attribute of the first link whose
    # 'rel' attribute is set to edit
    edit_link = REXML::XPath.first(xml, '//[@rel="edit"]')
    edit_link_href = edit_link.attribute('href').to_s
    # return the version string at the end of the link's href attribute
    return edit_link_href.split(/\//)[10]
  end

  # Perform a batch update using the cellsfeed of a specific spreadsheet
  #
  # Args:
  #   batch_data: array of hashes of data to post
  #               sample hash: +batch_id+: string (i.e. "A")
  #                            +cell_id+: string (i.e. "R1C1")
  #                            +data+: string (i.e. "My data")
  #
  # Returns:
  #   Net::HTTPResponse
  #
  def batch_update(batch_data, cellfeed_uri)
    batch_uri = cellfeed_uri + '/batch'

    batch_request = <<FEED
<?xml version="1.0" encoding="utf-8"?> \
  <feed xmlns="http://www.w3.org/2005/Atom" \
  xmlns:batch="http://schemas.google.com/gdata/batch" \
  xmlns:gs="http://schemas.google.com/spreadsheets/2006" \
  xmlns:gd="http://schemas.google.com/g/2005">
  <id>#{cellfeed_uri}</id>
FEED

    batch_data.each do |batch_request_data|
      version_string = get_version_string(cellfeed_uri + '/' +
          batch_request_data[:cell_id])
      data = batch_request_data[:data]
      batch_id = batch_request_data[:batch_id]
      cell_id = batch_request_data[:cell_id]
      row = batch_request_data[:cell_id][1,1]
      column = batch_request_data[:cell_id][3,1]
      edit_link = cellfeed_uri + '/' + cell_id + '/' + version_string
   
      batch_request<< <<ENTRY
          <entry>
            <gs:cell col="#{column}" inputValue="#{data}" row="#{row}"/>
            <batch:id>#{batch_id}</batch:id>
            <batch:operation type="update" />
            <id>#{cellfeed_uri}/#{cell_id}</id>
            <link href="#{edit_link}" rel="edit" type="application/atom+xml" />
          </entry>
ENTRY
  end
    
    batch_request << '</feed>'
    return post(batch_uri, batch_request)
  end
end



