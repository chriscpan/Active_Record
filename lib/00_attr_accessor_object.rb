class AttrAccessorObject

  def self.my_attr_accessor(*names)
    # ...
    names.each do |name|
      #getter
      define_method(name) do
        self.instance_variable_get("@#{name}")
      end

      define_method("#{name}=") do |val|
        self.instance_variable_set("@#{name}", val)
      end

    end

  end

end


class Dog < AttrAccessorObject
  self.my_attr_accessor(:name)

  def initialize(name)
    @name = name
  end

  def say_hi
    puts 'My name is:'
    puts name
  end

  def change_name_to(new_name)
    self.name=(new_name)
  end
end















      # #setter
      # name.each do |key, value|
      #   define_method(key, value) do
      #     self.instance_variable_set(key,value)
      #   end
      # end
