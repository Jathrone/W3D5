class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |name|
      attr_name = '@' + name.to_s
      define_method(name) {self.instance_variable_get(attr_name)}
      define_method("#{name}=") {|value| self.instance_variable_set(attr_name, value)}
    end
  end
end
