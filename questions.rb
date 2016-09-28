require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end
#
# class Everything
#   def initialize
#   end
#
#   def self.table
#     self.to_s.downcase + "s"
#   end
#
#   def self.find_by_id(id)
#     type_s = self.class.to_s.downcase + "s"
#     result = QuestionsDatabase.instance.execute(<<-SQL,id:id)
#     SELECT
#       *
#     FROM
#       #{table}
#     WHERE
#       id = :id
#     SQL
#     return nil unless result.length > 0
#     self.class.new(result.first)
#   end
# end

class User
  attr_accessor :fname, :lname
  attr_reader :id

  def self.find_by_id(id)
    user = QuestionsDatabase.instance.execute(<<-SQL,id)
    SELECT
      *
    FROM
      users
    WHERE
      id = ?
    SQL
    return nil unless user.length > 0
    User.new(user.first)
  end

  def self.find_by_name(fname,lname)
    user = QuestionsDatabase.instance.execute(<<-SQL,fname,lname)
    SELECT
      *
    FROM
      users
    WHERE
      fname = ? AND lname = ?
    SQL
    return nil unless user.length > 0
    User.new(user.first)
  end

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def authored_questions
    Question.find_by_author_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

  def followed_questions
    QuestionFollow.followed_questions_for_user_id(@id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

  def average_karma
    average = QuestionsDatabase.instance.execute(<<-SQL, id: @id)
    SELECT
      Cast(Count(user_id) AS FLOAT) / Count(DISTINCT(question_id))
    FROM
      questions

      LEFT OUTER JOIN question_likes
      ON questions.id = question_likes.question_id
    WHERE
      questions.author_id = :id
    SQL
    average[0].values.first
  end

  def save
    if @id.nil?
    QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
    INSERT INTO
      users(fname,lname)
    VALUES
      (?,?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id

    else
    QuestionsDatabase.instance.execute(<<-SQL, fname, lname, id)
    UPDATE
      users
    SET
      fname = ?, lname = ?
    WHERE
      id = ?
    SQL
    end
  end

end

class Question
  attr_accessor :title, :body
  attr_reader :user_id

  def self.find_by_author_id(author_id)
    question = QuestionsDatabase.instance.execute(<<-SQL, author_id)
    SELECT
      *
    FROM
      questions
    WHERE
      author_id = ?
  SQL
  return nil unless question.length > 0
  Question.new(question.first)
  end

  def self.find_by_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL,id)
    SELECT
      *
    FROM
      questions
    WHERE
      id = ?
    SQL
    return nil unless question.length > 0
    Question.new(question.first)
  end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body  = options['body']
    @author_id = options['author_id']
  end

  def author
    User.find_by_id(@author_id)
  end

  def replies
    Reply.find_by_question_id(@id)
  end

  def followers
    QuestionFollow.follows_for_question_id(@id)
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  def likers
    QuestionLike.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(@id)
  end

  def save
    if @id.nil?
    QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @author_id)
    INSERT INTO
      questions(title, body, author_id)
    VALUES
      (?,?,?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id

    else
    QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @author_id, @id)
    UPDATE
      questions
    SET
      title = ?, body = ?, author_id = ?
    WHERE
      id = ?
    SQL
    end
  end

end

class Reply
  attr_accessor :body
  attr_reader :id, :question_id, :parent_reply_id, :user_id

  def self.find_by_user_id(user_id)
    reply = QuestionsDatabase.instance.execute(<<-SQL,user_id)
    SELECT
      *
    FROM
      replies
    WHERE
      user_id = ?
  SQL
  return nil unless reply.length > 0
  reply.map { |datum| Reply.new(datum) }
  end

  def self.find_by_question_id(question_id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      *
    FROM
      replies
    WHERE
      question_id = ?
  SQL
  return nil unless reply.length > 0
  reply.map { |datum| Reply.new(datum) }
  end

  def self.find_by_id(id)
    reply = QuestionsDatabase.instance.execute(<<-SQL,id)
    SELECT
      *
    FROM
      replies
    WHERE
      id = ?
    SQL
    return nil unless reply.length > 0
    Reply.new(reply.first)
  end

  def initialize(options)
    @id = options['id']
    @body = options['body']
    @user_id = options['user_id']
    @question_id = options['question_id']
    @parent_reply_id = options['parent_reply_id']
  end

  def author
    User.find_by_id(@user_id)
  end

  def parent_reply
    Reply.find_by_id(@parent_reply_id)
  end

  def child_replies
    children = QuestionsDatabase.instance.execute(<<-SQL,@id)
    SELECT
      *
    FROM
      replies
    WHERE
      parent_reply_id = ?
    SQL
    return nil unless children.length > 0
    children.map { |datum| Reply.new(datum) }
  end

  def save
    if @id.nil?
    QuestionsDatabase.instance.execute(<<-SQL, @question_id, @parent_reply_id, @body, @user_id)
    INSERT INTO
      replies(question_id, parent_reply_id, body, user_id)
    VALUES
      (?,?,?,?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id

    else
    QuestionsDatabase.instance.execute(<<-SQL, @question_id, @parent_reply_id, @body, @user_id, @id)
    UPDATE
      replies
    SET
      question_id = ?, parent_reply_id = ?, body = ?, user_id = ?
    WHERE
      id = ?
    SQL
    end
  end

end

class QuestionFollow

  def self.follows_for_question_id(id)
    followers = QuestionsDatabase.instance.execute(<<-SQL, id: id)
    SELECT
      fname,lname
    FROM
      users
      JOIN question_follows
      ON users.id = question_follows.user_id
    WHERE
      :id = question_follows.question_id
    SQL
      return nil unless followers.length>0
      followers.map {|datum| User.new(datum)}
  end

  def self.followed_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id: user_id)
    SELECT
      title, body, author_id
    FROM
      questions
      JOIN question_follows
      ON questions.id = question_follows.question_id
    WHERE
      :user_id = question_follows.user_id
    SQL
      return nil unless questions.length>0
      questions.map {|datum| Question.new(datum)}
  end

  def self.most_followed_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n: n)
    SELECT
      title,body,author_id
    FROM
      questions
      JOIN question_follows
      ON questions.id = question_follows.question_id
    GROUP BY
      question_follows.question_id
    ORDER BY
      COUNT(question_id) DESC
    LIMIT
      :n
    SQL
    return nil unless questions.length>0
    questions.map {|datum| Question.new(datum)}
  end

end

class QuestionLike
  def self.likers_for_question_id(question_id)
    users = QuestionsDatabase.instance.execute(<<-SQL, question_id: question_id)
    SELECT
      fname,lname
    FROM
      users u
      JOIN question_likes ql
      ON ql.user_id = u.id
    WHERE
      :question_id = ql.question_id
    SQL
    return nil unless users.length > 0
    users.map { |datum| User.new(datum) }
  end

  def self.num_likes_for_question_id(question_id)
    likes = QuestionsDatabase.instance.execute(<<-SQL, question_id: question_id)
    SELECT
      Count(*)
    FROM
      question_likes
    GROUP BY
      question_likes.question_id
    HAVING
     :question_id = question_likes.question_id
    SQL
    p likes[0]["Count(*)"]
  end

  def self.liked_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id: user_id)
    SELECT
      title, body, author_id
    FROM
      questions q
      JOIN question_likes ql
      ON ql.question_id = q.id
    WHERE
      :user_id = ql.user_id
    SQL
    return nil unless questions.length > 0
    questions.map { |datum| Question.new(datum) }
  end

  def self.most_liked_questions(n)
      questions = QuestionsDatabase.instance.execute(<<-SQL, n: n)
      SELECT
        title,body,author_id
      FROM
        questions
        JOIN question_likes
        ON questions.id = question_likes.question_id
      GROUP BY
        question_likes.question_id
      ORDER BY
        COUNT(question_id) DESC
      LIMIT
        :n
      SQL
      return nil unless questions.length>0
      questions.map {|datum| Question.new(datum)}
  end

end
