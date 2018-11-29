require_relative "../config/environment.rb"
require 'active_support/inflector'
require "pry"

class InteractiveRecord

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true
    sql = "PRAGMA table_info('#{table_name}')"
    DB[:conn].execute(sql).map {|column| column["name"]}.compact
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT * FROM #{self.table_name}
      WHERE name = '#{name}'
    SQL
    DB[:conn].execute(sql)
  end

  def self.find_by(attr)
    sql = <<-SQL
      SELECT * FROM #{self.table_name}
      WHERE #{attr.keys[0].to_s} = '#{attr[attr.keys[0]]}'
    SQL
    DB[:conn].execute(sql)
  end

  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|attr| attr == "id"}.join(", ")
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |attr|
      values << "'#{send(attr)}'" if !send(attr).nil?
    end
    values.join(", ")
  end

  def save
    sql = <<-SQL
      INSERT INTO #{table_name_for_insert} (#{col_names_for_insert})
      VALUES (#{values_for_insert})
    SQL
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

end
