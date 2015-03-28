require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    cols = DBConnection::execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL

    cols.first.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |col|
      define_method(col) do
        attributes[col]
      end
      define_method("#{col}=") do |val|
        attributes[col] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    if @table_name.nil?
      @table_name = 'cats'
    else
      @table_name
    end
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
    SELECT
      #{@table_name}.*
    FROM
      #{@table_name}
    SQL

    self.parse_all(results)
  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
    SELECT
      *
    FROM
      #{@table_name}
    WHERE
      #{@table_name}.id = ?
    LIMIT
      1
    SQL

    parse_all(result).first
  end

  def initialize(params = {})
      params.each do |attr_name, value|
        attr_name = attr_name.to_sym
        if self.class.columns.include?(attr_name)
          # attributes.attr_name
           self.send("#{attr_name}=", value)
        else
          raise "unknown attribute '#{attr_name}'"
        end
      end
  end

  def attributes
    if @attributes.nil?
      @attributes = {}
    else
      @attributes
    end
  end

  def attribute_values
    self.class.columns.map do |column|
      self.send(column)
    end
  end

  def insert
    cols = self.class.columns.drop(1)
    column_names = cols.map(&:to_s).join(", ")
    question_marks = (["?"] * cols.count).join(", ")

    DBConnection.execute(<<-SQL, *attribute_values.drop(1))
      INSERT INTO
        #{self.class.table_name} (#{column_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    set = self.class.columns.map do |attr|
          "#{attr}= ?"
        end
    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set.join(", ")}
      WHERE
        #{self.class.table_name}.id = ?
    SQL

  end

  def save
    if id.nil?
      self.insert
    else
      self.update
    end
  end
end
