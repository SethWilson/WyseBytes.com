
class WikiEntry
  
  # a Wiki entry has...
  # - A Title
  # - A blurb of text
  # - some tags
  attr_accessor :title, :text, :tags
  
  def initialize(title, text, tags)
    @title = title
    @text = text
    @tags = tags
  end
  
end