class String
  def html_format
    str = Sanitize.clean(self);
    str.gsub(/[\s]+?/, "")
  end
end
