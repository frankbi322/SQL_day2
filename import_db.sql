DROP TABLE IF EXISTS users;

CREATE TABLE users (
id INTEGER PRIMARY KEY,
fname TEXT NOT NULL,
lname TEXT NOT NULL
);

DROP TABLE IF EXISTS questions;

CREATE TABLE questions (
id INTEGER PRIMARY KEY,
title TEXT NOT NULL,
body TEXT NOT NULL,
author_id INTEGER,

FOREIGN KEY (author_id) REFERENCES users(id)

);

DROP TABLE IF EXISTS question_follows;

CREATE TABLE question_follows (
  user_id INTEGER NOT NULL,
  question_id INTEGER,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

DROP TABLE IF EXISTS replies;

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER,
  parent_reply_id INTEGER,
  body TEXT NOT NULL,
  user_id INTEGER,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (parent_reply_id) REFERENCES replies(id)
);

DROP TABLE IF EXISTS question_likes;

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO
  users(fname,lname)
VALUES
  ('Frank','Bi'),
  ('Clint', 'Eastwood'),
  ('Dr','Evil');

INSERT INTO
  questions(title, body, author_id)
VALUES
  ('How I mine fish?', 'I have a pickaxe, how do I mine a fish?', '1'),
  ('Short length vs long length', 'Why is the word short longer than long?', '1'),
  ('Deep question?','What is the meaning of the universe?','1');

INSERT INTO
  replies(body,user_id, question_id)
VALUES
  ('You right click',2, 1);

INSERT INTO
  question_follows(user_id,question_id)
VALUES
  (1,2),
  (2,2),
  (3,1);

  INSERT INTO
    question_likes(user_id, question_id)
  VALUES
    (1,1),
    (2,2),
    (3,2);
