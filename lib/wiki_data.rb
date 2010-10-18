require 'lib/gs'
require 'lib/wiki_entry'

class WikiData

  attr_accessor :search_terms, :document_title, :login_email, :password
  attr_reader :wiki_data

    def initialize(document_title, search_terms, login_email, password)
      @document_title = document_title
      @search_terms = search_terms
      @login_email = login_email
      @password = password
      @wiki_data = []
    end


    # a Helper method to wrap search terms inside text with a certain style
    # FIXME I could override the String class 
   def summarize(text_to_summarize, search_terms)
      search_terms.each do |st|
        text_to_summarize.gsub!(/(#{st})/i, '*\1*')
      end
      return text_to_summarize
    end
    
    
    def get_wiki_data()
      
      gs = SpreadsheetExamples.new()

      gs.authenticate(@email, @password)
      @wiki_entries = gs.search_spreadsheet(gs.get_spreadsheet_key_by_title(@document_title), @search_terms)
      
       @wiki_entries["entry"].each do |we|
        # populate an array of wiki entry objects
        @wiki_data << WikiEntry.new(summarize(we['title'].pop, @search_terms), summarize(we['tags'].join(', '), @search_terms), summarize(we['text'].to_s, @search_terms))
        # puts "Title: #{summarize(we['title'].pop, search_terms)} Tags: #{summarize(we['tags'].join(', '), search_terms)} Text: #{summarize(we['text'].to_s, search_terms)}"
      end
      
      return @wiki_data
      
    end
    

  
end
