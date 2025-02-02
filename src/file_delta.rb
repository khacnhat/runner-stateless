
module FileDelta

  def file_delta(was, now)
    @changed = {}
    @deleted = {}
    was.each do |filename, file|
      if !now.has_key?(filename)
        @deleted[filename] = file
      elsif now[filename]['content'] != file['content']
        @changed[filename] = now[filename]
      end
      now.delete(filename) # destructive
    end
    @created = now
  end

end
