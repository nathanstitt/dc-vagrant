# Time to perform some recursive merging magic.

module HashMerge

  def self.perform( target, hash )

    hash.keys.each do |key|
      if hash[key].is_a? Hash and target[key].is_a? Hash
        target[key] = HashMerge.perform( target[key], hash[key] )
        next
      end
      target[key] = hash[key]
    end
    target
  end
end
