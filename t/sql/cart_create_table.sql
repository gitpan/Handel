CREATE TABLE cart (id varchar(36) NOT NULL default '',shopper varchar(36) NOT NULL default '',type tinyint(3) NOT NULL default '0',name varchar(50) default NULL,description varchar(255) default NULL,PRIMARY KEY (id));
CREATE TABLE cart_items (id varchar(36) NOT NULL default '',cart varchar(36) NOT NULL default '',sku varchar(25) NOT NULL default '',quantity tinyint(3) NOT NULL default '1',price decimal(9,2) NOT NULL default '0.00',description varchar(255) default NULL,PRIMARY KEY (id));
