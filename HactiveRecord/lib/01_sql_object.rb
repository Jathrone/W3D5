require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns
    data = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    @columns = data.first.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |column_name|
      define_method(column_name) {self.attributes[column_name]}
      define_method("#{column_name}=") {|val| self.attributes[column_name] = val}
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
    # ...
  end

  def self.table_name
    @table_name || self.to_s.tableize
    # ...
  end

  def self.all
    heredoc = <<-SQL
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
    SQL
    data = DBConnection.execute(heredoc)
    self.parse_all(data)
  end

  def self.parse_all(results)
    results.map {|datum| self.new(datum)}
    # ...
  end

  def self.find(id)
    heredoc = <<-SQL
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
      WHERE
        id = ?
      LIMIT
        1
    SQL
    data = DBConnection.execute(heredoc, id)
    self.parse_all(data).first
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      if self.class.columns.include?(attr_name)
        self.send("#{attr_name}=", value)
      else
        raise "unknown attribute '#{attr_name}'"
      end
    end
  end

  def attributes
    @attributes ||= {}
    @attributes
    # ...
  end

  def attribute_values
    self.class.columns.map {|col| self.send(col)}
  end

  def insert
    col_names = '(' + self.class.columns.join(',') + ')'
    question_marks = '(' + (["?"] * self.class.columns.count).join(',') + ')'

    DBConnection.execute(<<-SQL, *self.attribute_values)
      INSERT INTO
        #{self.class.table_name} #{col_names}
      VALUES
        #{question_marks}
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_line = (self.class.columns.map {|col| "#{col} = ?"}).join(',')
    DBConnection.execute(<<-SQL, *self.attribute_values, self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        id = ?
    SQL
  end

  def save
    id.nil? ? self.insert : self.update
  end
end


# module Searchable
#   def where(params)
#     where_line = (params.keys.map {|key| "#{key} = ?"}).join('AND')
#     data = DBConnection.execute(<<-SQL, params.values)
#       SELECT
#         *
#       FROM
#         #{self.table_name}
#       WHERE
#         #{where_line}
#     SQL
#     found = self.parse_all(data)
#     return found
#   end
# end