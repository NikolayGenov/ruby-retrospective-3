class Task
  attr_reader :status, :description, :priority, :tags

  def initialize(status, description, priority, tags)
    @status      = status
    @description = description
    @priority    = priority
    @tags        = tags
  end
end

class TodoList
  include Enumerable

  def self.parse(text)
    parsed_text = Parser.new(text) do |status, description, priority, tags|
      Task.new status, description, priority, tags
    end

    TodoList.new parsed_text.tasks
  end

  def initialize(tasks = [])
    @tasks = tasks
  end

  def filter(criteria)
    TodoList.new @tasks.select{ |task| criteria.matches? task }
  end

  def completed?
    tasks_completed.equal? tasks.size
  end

  def adjoin(other)
    TodoList.new tasks | other.tasks
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

  def each(&block)
    @tasks.each(&block)
  end

  protected

  attr_reader :tasks
end

class TodoList::Parser
  attr_reader :tasks

  def initialize(text, &block)
    @tasks = parse_lines(text).map(&block)
  end

  private

  def parse_lines(text)
    text.lines.map { |line| line.split('|').map(&:strip) }.map do |attributes|
      process_attributes(*attributes)
    end
  end

  def process_attributes(status, description, priority, tags)
    [status.downcase.to_sym,
     description,
     priority.downcase.to_sym,
     tags.split(',').map(&:strip),
    ]
  end
end

module Criteria
  class << self
    def status(status)
      Criterion.new { |task| task.status.equal? status }
    end

    def priority(priority)
      Criterion.new { |task| task.priority.equal? priority }
    end

    def tags(tags)
      Criterion.new { |task| (tags & task.tags).eql? tags }
    end
  end
end

class Criterion
  def initialize(&predicate)
    @predicate = predicate
  end

  def matches?(task)
    @predicate.(task)
  end

  def &(other)
    Criterion.new { |task| matches? task and other.matches? task }
  end

  def |(other)
    Criterion.new { |task| matches? task or other.matches? task }
  end

  def !
    Criterion.new { |task| not matches? task  }
  end
end
