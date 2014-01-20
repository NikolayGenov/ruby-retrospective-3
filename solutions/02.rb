class Criteria
  class << self
    def status(status)
      Criterion.new { |todo| todo.status.equal? status }
    end

    def priority(priority)
      Criterion.new { |todo| todo.priority.equal? priority }
    end

    def tags(tags)
      Criterion.new { |todo| tags & todo.tags == tags }
    end
  end
end

class Criterion
  def initialize(&block)
    @predicate = block
  end

  def matches?(todo)
    @predicate.(todo)
  end

  def &(other)
    Criterion.new { |todo| matches?(todo) and other.matches?(todo) }
  end

  def |(other)
    Criterion.new { |todo| matches?(todo) or other.matches?(todo) }
  end

  def !
    Criterion.new { |todo| not matches?(todo) }
  end
end

class Todo
  attr_reader :status, :description, :priority, :tags

  def initialize(status, description, priority, tags)
    @status      = status.downcase.to_sym
    @description = description
    @priority    = priority.downcase.to_sym
    @tags        = tags.split(",").map(&:strip)
  end
end

class TodoList
  include Enumerable

  attr_reader :todos

  def self.parse(todos_string)
    splited_str = todos_string.lines.map { |line| line.split("|").map(&:strip) }
    todos       = splited_str.map do |status, description, priority, tags|
      Todo.new status, description, priority, tags
    end

    new todos
  end

  def initialize(todos)
    @todos = todos
  end

  def each(&block)
    @todos.each(&block)
  end

  def tasks_todo
    (filter Criteria.status :todo).to_a.size
  end

  def tasks_in_progress
    (filter Criteria.status :current).to_a.size
  end

  def tasks_completed
    (filter Criteria.status :done).to_a.size
  end

  def completed?
    tasks_completed.equal? todos.size
  end

  def adjoin(other)
    TodoList.new todos | other.todos
  end

  def filter(criteria)
    TodoList.new @todos.select{ |todo| criteria.matches? todo }
  end
end
