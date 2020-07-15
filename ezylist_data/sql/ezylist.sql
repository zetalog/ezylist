CREATE DATABASE ezylist;

use ezylist;

CREATE TABLE member(
	username	varchar(8)	NOT NULL	PRIMARY KEY,
	name		varchar(60)	NOT NULL,
	email		varchar(60)	NOT NULL	UNIQUE,
	password	varchar(60)	NULL,
	class		varchar(15)	NOT NULL	DEFAULT "unregistered",
	status		varchar(10)	NOT NULL	DEFAULT "active",
	CONSTRAINT check_status CHECK(status in("active", "inactive")),
	CONSTRAINT check_class CHECK(class in("unregistered", "registered", "advertisr"))
);

INSERT INTO member VALUES(
	"mysql",
	"MySQL User",
	"mysql@foobar.com",
	"mysql",
	"unregistered",
	"active"
);
